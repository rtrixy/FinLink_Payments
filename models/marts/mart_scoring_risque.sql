WITH transactions AS (
    SELECT * FROM {{ ref('transactions_staging') }}
),

clients AS (
    SELECT * FROM {{ ref('base_crm_clients_staging') }}
),

litiges AS (
    SELECT * FROM {{ ref('logs_litiges_staging') }}
),

geoip AS (
    SELECT * FROM {{ ref('ip_geolocation_staging') }}
),

transactions_enrichies AS (
    SELECT
        t.transaction_id,
        t.client_id,
        t.montant_eur,
        t.statut,
        t.score_risque,
        t.device_type,
        g.pays,
        g.risque_pays,
        g.proxy_vpn_detecte
    FROM transactions t
    LEFT JOIN geoip g ON t.ip_id = g.ip_id
),

transactions_par_client AS (
    SELECT
        client_id,
        COUNT(transaction_id)                                               AS nb_transactions,
        SUM(montant_eur)                                                    AS montant_total_eur,
        AVG(score_risque)                                                   AS score_risque_moyen,
        MAX(score_risque)                                                   AS score_risque_max,
        SUM(CASE WHEN score_risque >= 70 THEN 1 ELSE 0 END)                AS nb_transactions_haut_risque,
        SUM(CASE WHEN statut = 'refuse' THEN 1 ELSE 0 END)                 AS nb_transactions_refusees,
        SUM(CASE WHEN proxy_vpn_detecte = TRUE THEN 1 ELSE 0 END)          AS nb_transactions_vpn,
        SUM(CASE WHEN risque_pays IN ('élevé', 'moyen') THEN 1 ELSE 0 END) AS nb_transactions_pays_risque
    FROM transactions_enrichies
    GROUP BY client_id
),

litiges_par_client AS (
    SELECT
        client_id,
        COUNT(litige_id)                                                    AS nb_litiges,
        SUM(montant_concerne_eur)                                           AS montant_total_litiges_eur,
        SUM(CASE WHEN issue = 'defavorable' THEN 1 ELSE 0 END)             AS nb_litiges_defavorables
    FROM litiges
    GROUP BY client_id
)

SELECT
    c.client_id,
    c.segment_client,
    c.anciennete_jours,
    c.taux_litiges_pct,
    COALESCE(t.nb_transactions, 0)                  AS nb_transactions,
    COALESCE(t.montant_total_eur, 0)                AS montant_total_eur,
    COALESCE(t.score_risque_moyen, 0)               AS score_risque_moyen,
    COALESCE(t.score_risque_max, 0)                 AS score_risque_max,
    COALESCE(t.nb_transactions_haut_risque, 0)      AS nb_transactions_haut_risque,
    COALESCE(t.nb_transactions_refusees, 0)         AS nb_transactions_refusees,
    COALESCE(t.nb_transactions_vpn, 0)              AS nb_transactions_vpn,
    COALESCE(t.nb_transactions_pays_risque, 0)      AS nb_transactions_pays_risque,
    COALESCE(l.nb_litiges, 0)                       AS nb_litiges,
    COALESCE(l.montant_total_litiges_eur, 0)        AS montant_total_litiges_eur,
    COALESCE(l.nb_litiges_defavorables, 0)          AS nb_litiges_defavorables,
    ROUND(
        (
            COALESCE(t.score_risque_moyen, 0) * 0.4 +
            COALESCE(c.taux_litiges_pct, 0)   * 0.3 +
            COALESCE(t.nb_transactions_haut_risque, 0) /
                NULLIF(t.nb_transactions, 0) * 100 * 0.2 +
            COALESCE(t.nb_transactions_vpn, 0) /
                NULLIF(t.nb_transactions, 0) * 100 * 0.1
        ), 2
    )                                               AS score_risque_global,
    CASE
        WHEN c.taux_litiges_pct >= 20
          OR t.score_risque_moyen >= 70
          OR t.nb_transactions_vpn >= 3             THEN 'Critique'
        WHEN c.taux_litiges_pct >= 10
          OR t.score_risque_moyen >= 50             THEN 'Élevé'
        WHEN c.taux_litiges_pct >= 5
          OR t.score_risque_moyen >= 30             THEN 'Modéré'
        ELSE                                             'Faible'
    END                                             AS categorie_risque
FROM clients c
LEFT JOIN transactions_par_client t ON c.client_id = t.client_id
LEFT JOIN litiges_par_client l      ON c.client_id = l.client_id
ORDER BY score_risque_global DESC
-- Mart principal : analyse du risque par client
-- Répond aux axes 1 & 2 de l'énoncé
-- Granularité : 1 ligne par client

WITH fact_tx AS (
    SELECT * FROM {{ ref('fact_transactions') }}
),

fact_lt AS (
    SELECT * FROM {{ ref('fact_litiges') }}
),

-- Agrégation transactions par client
tx_par_client AS (
    SELECT
        client_id,
        segment_client,
        anciennete_jours,
        categorie_anciennete,
        taux_litiges_pct,
        categorie_risque_historique,

        COUNT(transaction_id)                                               AS nb_transactions,
        SUM(montant_eur)                                                    AS montant_total_eur,
        AVG(score_risque)                                                   AS score_risque_moyen,
        MAX(score_risque)                                                   AS score_risque_max,
        SUM(CASE WHEN est_haut_risque  THEN 1 ELSE 0 END)                  AS nb_haut_risque,
        SUM(CASE WHEN est_refuse       THEN 1 ELSE 0 END)                  AS nb_refusees,
        SUM(CASE WHEN proxy_vpn_detecte THEN 1 ELSE 0 END)                 AS nb_vpn,
        SUM(CASE WHEN est_contexte_risque THEN 1 ELSE 0 END)               AS nb_contexte_risque,
        SUM(CASE WHEN categorie_device = 'Mobile' THEN 1 ELSE 0 END)       AS nb_transactions_mobile,
        SUM(CASE WHEN categorie_device = 'Desktop' THEN 1 ELSE 0 END)      AS nb_transactions_desktop,
        SUM(CASE WHEN categorie_device = 'Tablet' THEN 1 ELSE 0 END)       AS nb_transactions_tablet
    FROM fact_tx
    GROUP BY
        client_id, segment_client, anciennete_jours,
        categorie_anciennete, taux_litiges_pct, categorie_risque_historique
),

-- Agrégation litiges par client
lt_par_client AS (
    SELECT
        client_id,
        COUNT(litige_id)                                                    AS nb_litiges,
        SUM(montant_concerne_eur)                                           AS montant_total_litiges_eur,
        AVG(montant_concerne_eur)                                           AS montant_moyen_litige_eur,
        AVG(jours_apres_transaction)                                        AS delai_moyen_litige_jours,
        SUM(CASE WHEN est_defavorable  THEN 1 ELSE 0 END)                  AS nb_defavorables,
        SUM(CASE WHEN NOT est_defavorable THEN 1 ELSE 0 END)               AS nb_favorables,
        MAX(date_litige)                                                    AS date_dernier_litige
    FROM fact_lt
    GROUP BY client_id
)

SELECT
    t.client_id,
    t.segment_client,
    t.anciennete_jours,
    t.categorie_anciennete,
    t.taux_litiges_pct,
    t.categorie_risque_historique,

    -- Transactions
    t.nb_transactions,
    t.montant_total_eur,
    t.score_risque_moyen,
    t.score_risque_max,
    t.nb_haut_risque,
    t.nb_refusees,
    t.nb_vpn,
    t.nb_contexte_risque,
    t.nb_transactions_mobile,
    t.nb_transactions_desktop,
    t.nb_transactions_tablet,

    -- Litiges
    COALESCE(l.nb_litiges, 0)                   AS nb_litiges,
    COALESCE(l.montant_total_litiges_eur, 0)     AS montant_total_litiges_eur,
    COALESCE(l.montant_moyen_litige_eur, 0)      AS montant_moyen_litige_eur,
    COALESCE(l.delai_moyen_litige_jours, 0)      AS delai_moyen_litige_jours,
    COALESCE(l.nb_defavorables, 0)               AS nb_litiges_defavorables,
    COALESCE(l.nb_favorables, 0)                 AS nb_litiges_favorables,
    l.date_dernier_litige,

    -- Taux de litige calculé
    ROUND(
        COALESCE(l.nb_litiges, 0) /
        NULLIF(t.nb_transactions, 0) * 100, 2
    )                                            AS taux_litige_pct,

    -- Score de risque global pondéré
    ROUND(
        (
            t.score_risque_moyen * 0.4 +
            t.taux_litiges_pct   * 0.3 +
            COALESCE(l.nb_litiges, 0) / NULLIF(t.nb_transactions, 0) * 100 * 0.2 +
            t.nb_vpn / NULLIF(t.nb_transactions, 0) * 100 * 0.1
        ), 2
    )                                            AS score_risque_global,

    -- Catégorie de risque
    CASE
        WHEN t.taux_litiges_pct >= 20
          OR t.score_risque_moyen >= 70
          OR t.nb_vpn >= 3                       THEN 'Critique'
        WHEN t.taux_litiges_pct >= 10
          OR t.score_risque_moyen >= 50          THEN 'Élevé'
        WHEN t.taux_litiges_pct >= 5
          OR t.score_risque_moyen >= 30          THEN 'Modéré'
        ELSE                                          'Faible'
    END                                          AS categorie_risque

FROM tx_par_client t
LEFT JOIN lt_par_client l ON t.client_id = l.client_id
ORDER BY score_risque_global DESC
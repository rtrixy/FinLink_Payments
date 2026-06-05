WITH clients AS (
    SELECT * FROM {{ ref('base_crm_clients_staging') }}
),

litiges AS (
    SELECT * FROM {{ ref('logs_litiges_staging') }}
),

transactions AS (
    SELECT * FROM {{ ref('transactions_staging') }}
),

litiges_agreges AS (
    SELECT
        client_id,
        COUNT(litige_id)                                        AS nb_litiges,
        SUM(montant_concerne_eur)                               AS montant_total_litiges_eur,
        AVG(montant_concerne_eur)                               AS montant_moyen_litige_eur,
        AVG(jours_apres_transaction)                            AS delai_moyen_litige_jours,
        SUM(CASE WHEN issue = 'defavorable' THEN 1 ELSE 0 END) AS nb_litiges_defavorables,
        SUM(CASE WHEN issue = 'favorable' THEN 1 ELSE 0 END)   AS nb_litiges_favorables,
        MAX(date_litige)                                        AS date_dernier_litige
    FROM litiges
    GROUP BY client_id
),

transactions_agreges AS (
    SELECT
        client_id,
        COUNT(transaction_id)                                   AS nb_transactions_total,
        SUM(montant_eur)                                        AS montant_total_transactions_eur,
        AVG(score_risque)                                       AS score_risque_moyen,
        MAX(score_risque)                                       AS score_risque_max
    FROM transactions
    GROUP BY client_id
)

SELECT
    c.client_id,
    c.segment_client,
    c.anciennete_jours,
    c.nb_achats_historique,
    c.taux_litiges_pct,
    COALESCE(l.nb_litiges, 0)                          AS nb_litiges,
    COALESCE(l.montant_total_litiges_eur, 0)           AS montant_total_litiges_eur,
    COALESCE(l.montant_moyen_litige_eur, 0)            AS montant_moyen_litige_eur,
    COALESCE(l.delai_moyen_litige_jours, 0)            AS delai_moyen_litige_jours,
    COALESCE(l.nb_litiges_defavorables, 0)             AS nb_litiges_defavorables,
    COALESCE(l.nb_litiges_favorables, 0)               AS nb_litiges_favorables,
    l.date_dernier_litige,
    COALESCE(t.nb_transactions_total, 0)               AS nb_transactions_total,
    COALESCE(t.montant_total_transactions_eur, 0)      AS montant_total_transactions_eur,
    COALESCE(t.score_risque_moyen, 0)                  AS score_risque_moyen,
    COALESCE(t.score_risque_max, 0)                    AS score_risque_max
FROM clients c
LEFT JOIN litiges_agreges l      ON c.client_id = l.client_id
LEFT JOIN transactions_agreges t ON c.client_id = t.client_id
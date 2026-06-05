-- Question : Délai de résolution et types de litiges fréquents

WITH litiges AS (
    SELECT * FROM {{ ref('logs_litiges_staging') }}
),

transactions AS (
    SELECT * FROM {{ ref('transactions_staging') }}
)

SELECT
    l.type_litige,
    l.issue,

    -- Volume
    COUNT(l.litige_id)                                      AS nb_litiges,
    ROUND(
        COUNT(l.litige_id) /
        SUM(COUNT(l.litige_id)) OVER() * 100, 2
    )                                                       AS pct_litiges_total,

    -- Montants
    SUM(l.montant_concerne_eur)                             AS montant_total_eur,
    AVG(l.montant_concerne_eur)                             AS montant_moyen_eur,
    MAX(l.montant_concerne_eur)                             AS montant_max_eur,

    -- Délais
    AVG(l.jours_apres_transaction)                          AS delai_moyen_jours,
    MIN(l.jours_apres_transaction)                          AS delai_min_jours,
    MAX(l.jours_apres_transaction)                          AS delai_max_jours,

    -- Score risque moyen des transactions litigieuses
    AVG(t.score_risque)                                     AS score_risque_moyen_transaction

FROM litiges l
LEFT JOIN transactions t ON l.transaction_id = t.transaction_id
GROUP BY l.type_litige, l.issue
ORDER BY nb_litiges DESC
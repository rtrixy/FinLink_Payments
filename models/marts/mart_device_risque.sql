-- Question : Quel est le taux de litige par device ?

WITH transactions AS (
    SELECT * FROM {{ ref('transactions_staging') }}
),

litiges AS (
    SELECT * FROM {{ ref('logs_litiges_staging') }}
),

-- Transactions par device
transactions_device AS (
    SELECT
        device_type,
        COUNT(transaction_id)                               AS nb_transactions,
        SUM(montant_eur)                                    AS montant_total_eur,
        AVG(score_risque)                                   AS score_risque_moyen,
        SUM(CASE WHEN statut = 'refuse' THEN 1 ELSE 0 END) AS nb_refusees
    FROM transactions
    GROUP BY device_type
),

-- Litiges par device (via jointure transaction → litige)
litiges_device AS (
    SELECT
        t.device_type,
        COUNT(l.litige_id)                                  AS nb_litiges,
        SUM(l.montant_concerne_eur)                         AS montant_total_litiges_eur,
        AVG(l.montant_concerne_eur)                         AS montant_moyen_litige_eur
    FROM transactions t
    LEFT JOIN litiges l ON t.transaction_id = l.transaction_id
    WHERE l.litige_id IS NOT NULL
    GROUP BY t.device_type
)

SELECT
    t.device_type,
    -- Catégorie device
    CASE
        WHEN t.device_type IN ('mobile_ios', 'mobile_android') THEN 'Mobile'
        WHEN t.device_type = 'desktop'                         THEN 'Desktop'
        WHEN t.device_type = 'tablet'                          THEN 'Tablet'
        ELSE 'Autre'
    END                                                     AS categorie_device,
    t.nb_transactions,
    t.montant_total_eur,
    t.score_risque_moyen,
    t.nb_refusees,
    COALESCE(l.nb_litiges, 0)                               AS nb_litiges,
    COALESCE(l.montant_total_litiges_eur, 0)                AS montant_total_litiges_eur,
    COALESCE(l.montant_moyen_litige_eur, 0)                 AS montant_moyen_litige_eur,
    ROUND(
        COALESCE(l.nb_litiges, 0) /
        NULLIF(t.nb_transactions, 0) * 100, 2
    )                                                       AS taux_litige_pct
FROM transactions_device t
LEFT JOIN litiges_device l ON t.device_type = l.device_type
ORDER BY taux_litige_pct DESC
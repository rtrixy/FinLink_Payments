-- Question : % litiges interceptés par niveau de risque pays

WITH transactions AS (
    SELECT * FROM {{ ref('transactions_staging') }}
),

geoip AS (
    SELECT * FROM {{ ref('ip_geolocation_staging') }}
),

litiges AS (
    SELECT * FROM {{ ref('logs_litiges_staging') }}
),

transactions_geo AS (
    SELECT
        t.transaction_id,
        t.montant_eur,
        t.statut,
        g.pays,
        g.risque_pays,
        g.proxy_vpn_detecte
    FROM transactions t
    LEFT JOIN geoip g ON t.ip_id = g.ip_id
),

litiges_geo AS (
    SELECT
        l.litige_id,
        l.transaction_id,
        l.montant_concerne_eur,
        t.risque_pays,
        t.pays,
        t.proxy_vpn_detecte
    FROM litiges l
    LEFT JOIN transactions_geo t ON l.transaction_id = t.transaction_id
)

SELECT
    tg.risque_pays,
    COUNT(DISTINCT tg.transaction_id)                       AS nb_transactions,
    ROUND(
        COUNT(DISTINCT tg.transaction_id) /
        SUM(COUNT(DISTINCT tg.transaction_id)) OVER() * 100, 2
    )                                                       AS pct_transactions_total,
    COUNT(DISTINCT lg.litige_id)                            AS nb_litiges,
    ROUND(
        COUNT(DISTINCT lg.litige_id) /
        SUM(COUNT(DISTINCT lg.litige_id)) OVER() * 100, 2
    )                                                       AS pct_litiges_total,
    SUM(lg.montant_concerne_eur)                            AS montant_litiges_eur,
    ROUND(
        SUM(lg.montant_concerne_eur) /
        SUM(SUM(lg.montant_concerne_eur)) OVER() * 100, 2
    )                                                       AS pct_montant_litiges_total,
    ROUND(
        COUNT(DISTINCT lg.litige_id) /
        NULLIF(COUNT(DISTINCT tg.transaction_id), 0) * 100, 2
    )                                                       AS taux_litige_pct
FROM transactions_geo tg
LEFT JOIN litiges_geo lg ON tg.transaction_id = lg.transaction_id
GROUP BY tg.risque_pays
ORDER BY nb_litiges DESC

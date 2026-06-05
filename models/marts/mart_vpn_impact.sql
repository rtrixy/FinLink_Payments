-- Question : Impact VPN/Proxy sur les litiges

WITH transactions AS (
    SELECT * FROM {{ ref('transactions_staging') }}
),

geoip AS (
    SELECT * FROM {{ ref('ip_geolocation_staging') }}
),

litiges AS (
    SELECT * FROM {{ ref('logs_litiges_staging') }}
),

-- Enrichissement transactions avec VPN
transactions_vpn AS (
    SELECT
        t.transaction_id,
        t.client_id,
        t.montant_eur,
        t.statut,
        t.score_risque,
        g.proxy_vpn_detecte,
        g.risque_pays
    FROM transactions t
    LEFT JOIN geoip g ON t.ip_id = g.ip_id
),

-- Litiges enrichis
litiges_enrichis AS (
    SELECT
        l.litige_id,
        l.transaction_id,
        l.montant_concerne_eur,
        l.issue,
        t.proxy_vpn_detecte,
        t.risque_pays
    FROM litiges l
    LEFT JOIN transactions_vpn t ON l.transaction_id = t.transaction_id
)

SELECT
    tv.proxy_vpn_detecte,

    COUNT(DISTINCT tv.transaction_id)                       AS nb_transactions,
    ROUND(
        COUNT(DISTINCT tv.transaction_id) /
        SUM(COUNT(DISTINCT tv.transaction_id)) OVER() * 100, 2
    )                                                       AS pct_volume_total,
    COUNT(DISTINCT le.litige_id)                            AS nb_litiges,
    SUM(le.montant_concerne_eur)                            AS montant_total_litiges_eur,
    ROUND(
        COUNT(DISTINCT le.litige_id) /
        NULLIF(COUNT(DISTINCT tv.transaction_id), 0) * 100, 2
    )                                                       AS taux_litige_pct,
    ROUND(
        SUM(le.montant_concerne_eur) /
        SUM(SUM(le.montant_concerne_eur)) OVER() * 100, 2
    )                                                       AS pct_montant_litiges_total

FROM transactions_vpn tv
LEFT JOIN litiges_enrichis le ON tv.transaction_id = le.transaction_id
GROUP BY tv.proxy_vpn_detecte
ORDER BY tv.proxy_vpn_detecte DESC
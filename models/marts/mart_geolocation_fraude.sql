WITH transactions AS (
    SELECT * FROM {{ ref('transactions_staging') }}
),

geoip AS (
    SELECT * FROM {{ ref('ip_geolocation_staging') }}
),

transactions_geo AS (
    SELECT
        t.transaction_id,
        t.client_id,
        t.montant_eur,
        t.statut,
        t.score_risque,
        t.device_type,
        t.date_heure,
        g.pays,
        g.ville,
        g.proxy_vpn_detecte,
        g.risque_pays
    FROM transactions t
    LEFT JOIN geoip g ON t.ip_id = g.ip_id
)

SELECT
    pays,
    risque_pays,
    proxy_vpn_detecte,
    COUNT(transaction_id)                                           AS nb_transactions,
    COUNT(DISTINCT client_id)                                       AS nb_clients_distincts,
    SUM(montant_eur)                                                AS montant_total_eur,
    AVG(montant_eur)                                                AS montant_moyen_eur,
    AVG(score_risque)                                               AS score_risque_moyen,
    MAX(score_risque)                                               AS score_risque_max,
    SUM(CASE WHEN score_risque >= 70 THEN 1 ELSE 0 END)            AS nb_transactions_haut_risque,
    SUM(CASE WHEN statut = 'approuve' THEN 1 ELSE 0 END)           AS nb_approuvees,
    SUM(CASE WHEN statut = 'refuse' THEN 1 ELSE 0 END)             AS nb_refusees,
    SUM(CASE WHEN statut = 'en_cours' THEN 1 ELSE 0 END)           AS nb_en_cours,
    ROUND(
        SUM(CASE WHEN statut = 'refuse' THEN 1 ELSE 0 END) /
        COUNT(transaction_id) * 100, 2
    )                                                               AS taux_refus_pct
FROM transactions_geo
GROUP BY pays, risque_pays, proxy_vpn_detecte
ORDER BY nb_transactions_haut_risque DESC
-- Table de faits : transactions enrichies avec géo et client
WITH transactions AS (
    SELECT * FROM {{ ref('transactions_staging') }}
),

dim_geo AS (
    SELECT * FROM {{ ref('dim_geolocation') }}
),

dim_cli AS (
    SELECT * FROM {{ ref('dim_clients') }}
)

SELECT
    -- Clés
    t.transaction_id,
    t.client_id,
    t.ip_id,

    -- Données transaction
    t.montant_eur,
    t.device_type,
    t.date_heure,
    t.statut,
    t.score_risque,

    -- Catégorie device
    CASE
        WHEN t.device_type IN ('mobile_ios', 'mobile_android') THEN 'Mobile'
        WHEN t.device_type = 'desktop'                         THEN 'Desktop'
        WHEN t.device_type = 'tablet'                          THEN 'Tablet'
        ELSE 'Autre'
    END AS categorie_device,

    -- Données géo
    g.pays,
    g.ville,
    g.proxy_vpn_detecte,
    g.risque_pays,
    g.score_risque_pays,
    g.est_contexte_risque,

    -- Données client
    c.segment_client,
    c.anciennete_jours,
    c.categorie_anciennete,
    c.taux_litiges_pct,
    c.categorie_risque_historique,

    -- Flags transaction
    CASE WHEN t.score_risque >= 70 THEN TRUE ELSE FALSE END AS est_haut_risque,
    CASE WHEN t.statut = 'refuse'  THEN TRUE ELSE FALSE END AS est_refuse,
    CASE WHEN t.statut = 'approuve' THEN TRUE ELSE FALSE END AS est_approuve

FROM transactions t
LEFT JOIN dim_geo g ON t.ip_id      = g.ip_id
LEFT JOIN dim_cli c ON t.client_id  = c.client_id
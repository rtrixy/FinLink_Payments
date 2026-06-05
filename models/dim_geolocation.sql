-- Dimension géolocalisation enrichie
WITH source AS (
    SELECT * FROM {{ ref('ip_geolocation_staging') }}
)

SELECT
    ip_id,
    adresse_ip,
    pays,
    ville,
    proxy_vpn_detecte,
    risque_pays,

    -- Score numérique du risque pays
    CASE risque_pays
        WHEN 'élevé' THEN 3
        WHEN 'moyen' THEN 2
        WHEN 'faible' THEN 1
        ELSE 0
    END AS score_risque_pays,

    -- Flag combiné VPN + pays risqué
    CASE
        WHEN proxy_vpn_detecte = TRUE
          OR risque_pays IN ('élevé', 'moyen') THEN TRUE
        ELSE FALSE
    END AS est_contexte_risque

FROM source
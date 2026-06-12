-- models/intermediate/dim_geolocation.sql
-- Dimension géolocalisation enrichie

-- BUG CORRIGÉ : les modalités réelles de risque_pays sont
-- 'faible' / 'moyen' / 'eleve' / 'tres eleve' (sans accents,
-- normalisées en amont par le pipeline Python).
-- L'ancien CASE testait 'élevé' (avec accents) -> aucun match :
-- les pays à risque élevé étaient scorés 0 et exclus du flag
-- est_contexte_risque, faussant tout l'axe 2 (contrôles géographiques).

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

    -- Score ordinal du risque pays (4 niveaux réels)
    CASE risque_pays
        WHEN 'tres eleve' THEN 4
        WHEN 'eleve'      THEN 3
        WHEN 'moyen'      THEN 2
        WHEN 'faible'     THEN 1
        ELSE 0   -- valeur inattendue : visible (0) plutôt que silencieuse
    END AS score_risque_pays,

    -- Flag combiné VPN + pays risqué (spécification de l'énoncé, axe 2 :
    -- « VPN/Proxy détecté OU pays à risque élevé ou moyen »)
    CASE
        WHEN proxy_vpn_detecte = TRUE
          OR risque_pays IN ('tres eleve', 'eleve', 'moyen') THEN TRUE
        ELSE FALSE
    END AS est_contexte_risque

FROM source
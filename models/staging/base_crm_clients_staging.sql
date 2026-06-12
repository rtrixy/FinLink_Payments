
WITH source AS (
    SELECT * FROM {{ source('data_finlink', 'base_crm_clients') }}
)

SELECT
    client_id,
    CAST(anciennete_jours AS INT64)                         AS anciennete_jours,
    CAST(nb_achats_historique AS INT64)                     AS nb_achats_historique,
    CAST(taux_litiges_pct AS FLOAT64)                       AS taux_litiges_pct,
    segment_client,
    CAST(date_inscription AS DATE)                          AS date_inscription
FROM source
WHERE CAST(taux_litiges_pct AS FLOAT64) <= 100
  AND segment_client IS NOT NULL
  AND segment_client != ''
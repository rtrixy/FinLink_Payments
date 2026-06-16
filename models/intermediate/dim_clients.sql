-- Dimension clients enrichie : quartiles d'ancienneté + risque historique

WITH source AS (
    SELECT * FROM {{ ref('base_crm_clients_staging') }}
)

SELECT
    client_id,
    segment_client,
    anciennete_jours,
    nb_achats_historique,
    taux_litiges_pct,
    date_inscription,

    -- Quartile statistique d'ancienneté (NTILE : 4 groupes d'effectifs
    -- égaux ; quartile 1 = les 25 % de clients les plus récents).
    -- Répond directement à la question Axe 1.2 : « quel quartile de
    -- nouveaux clients présente le taux de litige le plus élevé ? »
    NTILE(4) OVER (ORDER BY anciennete_jours) AS quartile_anciennete,

    -- Buckets métier (seuils fixes, lisibles) — complément Power BI
    CASE
        WHEN anciennete_jours <= 90  THEN 'Nouveau'
        WHEN anciennete_jours <= 365 THEN 'Moyen'
        WHEN anciennete_jours <= 730 THEN 'Ancien'
        ELSE                              'Historique'
    END AS categorie_anciennete


FROM source
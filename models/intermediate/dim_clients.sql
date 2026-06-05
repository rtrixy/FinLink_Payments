-- Dimension clients enrichie avec catégorie ancienneté
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

    -- Catégorie ancienneté (quartiles métier)
    CASE
        WHEN anciennete_jours <= 90  THEN 'Q1 — Très nouveau'
        WHEN anciennete_jours <= 365 THEN 'Q2 — Nouveau'
        WHEN anciennete_jours <= 730 THEN 'Q3 — Établi'
        ELSE                              'Q4 — Fidèle'
    END AS categorie_anciennete,

    -- Catégorie risque historique
    CASE
        WHEN taux_litiges_pct >= 20 THEN 'Risque élevé'
        WHEN taux_litiges_pct >= 10 THEN 'Risque modéré'
        WHEN taux_litiges_pct >= 5  THEN 'Risque faible'
        ELSE                             'Risque très faible'
    END AS categorie_risque_historique

FROM source
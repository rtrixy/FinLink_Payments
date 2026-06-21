
--J'enrichis le client avec deux découpages d'ancienneté : un quartile statistique (NTILE,
--4 groupes égaux) et des buckets métier lisibles. Et je retire taux_litiges_pct : c'est un
--taux déclaré du CRM qui ne reflète pas le risque réel — le garder créerait une colonne fantôme. 
WITH source AS (
    SELECT * FROM {{ ref('base_crm_clients_staging') }}
)

SELECT
    client_id,
    segment_client,
    anciennete_jours,
    nb_achats_historique,
    date_inscription,

    -- Quartile statistique d'ancienneté (NTILE : 4 groupes d'effectifs
    -- égaux ; quartile 1 = les 25 % de clients les plus récents).

    NTILE(4) OVER (ORDER BY anciennete_jours) AS quartile_anciennete,

    -- Buckets métier (seuils fixes, lisibles) — complément Power BI
    CASE
        WHEN anciennete_jours <= 90  THEN 'Nouveau'
        WHEN anciennete_jours <= 365 THEN 'Moyen'
        WHEN anciennete_jours <= 730 THEN 'Ancien'
        ELSE                              'Historique'
    END AS categorie_anciennete

FROM source
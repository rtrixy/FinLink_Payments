-- models/marts/dim_clients.sql
-- Dimension clients enrichie : quartiles d'ancienneté

-- NB : le champ source taux_litiges_pct (taux déclaré côté CRM, moyenne
-- 4,02 % sur les 5000 clients) est volontairement EXCLU du modèle.
-- Il ne correspond pas au taux réel recalculé sur les transactions
-- (2,98 % global).
-- Le garder serait une colonne fantôme : présente mais jamais interrogée,
-- source de confusion si quelqu'un l'utilise par erreur à la place du
-- taux réel calculé en DAX sur fact_transactions.

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
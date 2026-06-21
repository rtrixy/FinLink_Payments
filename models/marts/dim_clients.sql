
--J'enrichis le client avec deux découpages d'ancienneté : un quartile statistique (NTILE,
--4 groupes égaux) et des buckets métier lisibles. Et je retire taux_litiges_pct : c'est un
--taux déclaré du CRM qui ne reflète pas le risque réel — le garder créerait une colonne fantôme. 
SELECT
    client_id, segment_client, anciennete_jours, nb_achats_historique, date_inscription,
    NTILE(4) OVER (ORDER BY anciennete_jours) AS quartile_anciennete,  -- 4 groupes d'effectifs égaux
    CASE
        WHEN anciennete_jours <= 90  THEN 'Nouveau'
        WHEN anciennete_jours <= 365 THEN 'Moyen'
        WHEN anciennete_jours <= 730 THEN 'Ancien'
        ELSE                              'Historique'
    END AS categorie_anciennete
FROM {{ ref('base_crm_clients_staging') }}
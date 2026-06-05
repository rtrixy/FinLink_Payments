-- Table de faits : litiges enrichis avec transaction + client + géo
WITH litiges AS (
    SELECT * FROM {{ ref('logs_litiges_staging') }}
),

fact_tx AS (
    SELECT * FROM {{ ref('fact_transactions') }}
)

SELECT
    -- Clés
    l.litige_id,
    l.transaction_id,
    l.client_id,

    -- Données litige
    l.type_litige,
    l.montant_concerne_eur,
    l.date_litige,
    l.date_transaction,
    l.issue,
    l.jours_apres_transaction,

    -- Flag issue
    CASE WHEN l.issue = 'defavorable' THEN TRUE ELSE FALSE END AS est_defavorable,

    -- Données transaction enrichies
    t.montant_eur               AS montant_transaction_eur,
    t.device_type,
    t.categorie_device,
    t.statut                    AS statut_transaction,
    t.score_risque,
    t.est_haut_risque,

    -- Données géo
    t.pays,
    t.ville,
    t.proxy_vpn_detecte,
    t.risque_pays,
    t.score_risque_pays,
    t.est_contexte_risque,

    -- Données client
    t.segment_client,
    t.anciennete_jours,
    t.categorie_anciennete,
    t.taux_litiges_pct,
    t.categorie_risque_historique

FROM litiges l
LEFT JOIN fact_tx t ON l.transaction_id = t.transaction_id
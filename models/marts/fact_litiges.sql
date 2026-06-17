-- models/marts/fact_litiges.sql
-- Table de faits : litiges enrichis avec transaction + client + géo

-- AJOUT : famille_litige (Fraude / Commercial), construite à partir des
-- 6 modalités réelles de type_litige. C'est le seul axe qui révèle un
-- vrai écart dans l'analyse (taux défavorable 61,6 % Fraude vs 38,8 %
-- Commercial — page 3 du dashboard) : la régulation carte bancaire
-- laisse peu de marge de contestation au marchand sur un cas de fraude,
-- alors qu'un litige commercial (livraison, conformité) se défend
-- souvent avec une preuve. Construite ici, dans dbt, pour rester
-- cohérent avec l'architecture du projet : la logique métier est
-- versionnée en SQL, pas éparpillée en DAX.

-- SUPPRIMÉ : est_defavorable / est_favorable / est_en_cours (3 booléens
-- qui ne faisaient que recopier la colonne issue déjà propre à 3
-- modalités). Les mesures DAX filtrent directement sur issue.
-- SUPPRIMÉ : est_haut_risque, taux_litiges_pct (cf. notes dans
-- fact_transactions et dim_clients).

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

    -- Famille de litige (Fraude = usurpation/sécurité, levier = contrôles
    -- géo/VPN ; Commercial = qualité de service, levier = back-office et
    -- preuve de livraison/conformité)
    CASE
        WHEN l.type_litige IN ('fraude CB', 'non autorise') THEN 'Fraude'
        ELSE 'Commercial'
    END AS famille_litige,

    -- Données transaction enrichies
    t.montant_eur        AS montant_transaction_eur,
    t.categorie_device,
    t.statut              AS statut_transaction,
    t.score_risque,

    -- Données géo
    t.pays,
    t.ville,
    t.proxy_vpn_detecte,
    t.risque_pays,
    t.score_risque_pays,
    t.est_contexte_risque,

    -- Données client
    t.segment_client,
    t.categorie_anciennete

FROM litiges l
LEFT JOIN fact_tx t ON l.transaction_id = t.transaction_id
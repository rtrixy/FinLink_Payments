-- models/marts/fact_transactions.sql
-- Table de faits : transactions enrichies avec géo et client

-- NB modélisation : on conserve device_type (brut, 5 modalités) ET
-- categorie_device (regroupé, 3 modalités) car les deux servent : le
-- premier pour le détail technique, le second pour les visuels Power BI
-- où un regroupement Mobile/Tablet/Desktop est plus lisible.
-- BUG CORRIGÉ (historique) : l'ancien CASE testait l'égalité stricte sur
-- 'tablet' sans wildcard -> tablet_ios/tablet_android tombaient dans
-- 'Autre'. Le LIKE 'tablet%' ci-dessous couvre les deux modalités réelles.

-- SUPPRIMÉ : est_haut_risque (seuil arbitraire à 70 sur score_risque,
-- ne capture que 0,6 % des transactions et score_risque ne discrimine
-- pas le risque réel observé — moyenne quasi identique avec/sans litige).
-- SUPPRIMÉ : taux_litiges_pct (champ CRM déclaré, cf. note dans dim_clients).

WITH transactions AS (
    SELECT * FROM {{ ref('transactions_staging') }}
),

dim_geo AS (
    SELECT * FROM {{ ref('dim_geolocation') }}
),

dim_cli AS (
    SELECT * FROM {{ ref('dim_clients') }}
),

litiges AS (
    SELECT DISTINCT transaction_id FROM {{ ref('logs_litiges_staging') }}
)

SELECT
    -- Clés
    t.transaction_id,
    t.client_id,
    t.ip_id,

    -- Données transaction
    t.montant_eur,
    t.device_type,
    t.date_heure,
    t.statut,
    t.score_risque,

    -- Catégorie device (regroupement lisible pour Power BI)
    CASE
        WHEN t.device_type LIKE 'mobile%' THEN 'Mobile'
        WHEN t.device_type LIKE 'tablet%' THEN 'Tablet'
        WHEN t.device_type = 'desktop'    THEN 'Desktop'
        ELSE 'Autre'
    END AS categorie_device,

    -- Données géo
    g.pays,
    g.ville,
    g.proxy_vpn_detecte,
    g.risque_pays,
    g.score_risque_pays,
    g.est_contexte_risque,

    -- Données client
    c.segment_client,
    c.anciennete_jours,
    c.categorie_anciennete,

    -- Flags transaction
    CASE WHEN t.statut = 'refuse'   THEN TRUE ELSE FALSE END AS est_refuse,
    CASE WHEN t.statut = 'approuve' THEN TRUE ELSE FALSE END AS est_approuve,

    -- a_genere_litige porté ici (dénominateur du taux), pas dans
    -- fact_litiges : voir note d'architecture dans le dossier (chap. 5.3).
    CASE WHEN lt.transaction_id IS NOT NULL THEN TRUE ELSE FALSE END AS a_genere_litige

FROM transactions t
LEFT JOIN dim_geo g  ON t.ip_id      = g.ip_id
LEFT JOIN dim_cli c  ON t.client_id  = c.client_id
LEFT JOIN litiges lt ON t.transaction_id = lt.transaction_id
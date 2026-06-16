-- Mart principal : analyse du risque par client
-- Répond aux axes 1 (Q1 segment, Q2 ancienneté)
-- Granularité : 1 ligne par client
-- NB : Q3 (device), Q4/Q5 (VPN/pays) sont calculées directement sur
-- fact_transactions en DAX, pas ici : ce ne sont pas des analyses
-- "par client", les pré-agréger ici aurait fait doublon inutile.

WITH fact_tx AS (
    SELECT * FROM {{ ref('fact_transactions') }}
),

fact_lt AS (
    SELECT * FROM {{ ref('fact_litiges') }}
),

-- Agrégation transactions par client
tx_par_client AS (
    SELECT
        client_id,
        segment_client,
        anciennete_jours,
        categorie_anciennete,
        taux_litiges_pct,

        COUNT(transaction_id)                              AS nb_transactions,
        SUM(montant_eur)                                   AS montant_total_eur,
        AVG(score_risque)                                  AS score_risque_moyen,
        SUM(CASE WHEN est_haut_risque THEN 1 ELSE 0 END)   AS nb_haut_risque,
        SUM(CASE WHEN est_refuse THEN 1 ELSE 0 END)        AS nb_refusees
    FROM fact_tx
    GROUP BY
        client_id, segment_client, anciennete_jours,
        categorie_anciennete, taux_litiges_pct
),

-- Agrégation litiges par client
lt_par_client AS (
    SELECT
        client_id,
        COUNT(litige_id)                                   AS nb_litiges,
        SUM(montant_concerne_eur)                          AS montant_total_litiges_eur,
        AVG(montant_concerne_eur)                          AS montant_moyen_litige_eur,
        SUM(CASE WHEN est_defavorable THEN 1 ELSE 0 END)   AS nb_defavorables,
        SUM(CASE WHEN est_favorable   THEN 1 ELSE 0 END)   AS nb_favorables
    FROM fact_lt
    GROUP BY client_id
)

SELECT
    t.client_id,
    t.segment_client,
    t.anciennete_jours,
    t.categorie_anciennete,
    t.taux_litiges_pct,

    -- Transactions
    t.nb_transactions,
    t.montant_total_eur,
    t.score_risque_moyen,
    t.nb_haut_risque,
    t.nb_refusees,

    -- Litiges
    COALESCE(l.nb_litiges, 0)                AS nb_litiges,
    COALESCE(l.montant_total_litiges_eur, 0) AS montant_total_litiges_eur,
    COALESCE(l.montant_moyen_litige_eur, 0)  AS montant_moyen_litige_eur,
    COALESCE(l.nb_defavorables, 0)           AS nb_litiges_defavorables,
    COALESCE(l.nb_favorables, 0)             AS nb_litiges_favorables,

    -- Taux de litige réel recalculé (sert Q1 par segment, Q2 par quartile d'ancienneté)
    -- Nommé "reel" pour le distinguer explicitement de taux_litiges_pct (déclaré, CRM)
    ROUND(
        COALESCE(l.nb_litiges, 0) /
        NULLIF(t.nb_transactions, 0) * 100, 2
    )                                         AS taux_litige_reel_pct

FROM tx_par_client t
LEFT JOIN lt_par_client l ON t.client_id = l.client_id
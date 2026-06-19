-- models/marts/mart_analyse_risque.sql
-- Mart principal : analyse du risque par client
-- Granularité : 1 ligne par client

-- Ce mart agrège deux tables de faits à des granularités différentes
-- (transaction et litige) en une seule ligne par client.


WITH fact_tx AS (
    SELECT * FROM {{ ref('fact_transactions') }}
),

fact_lt AS (
    SELECT * FROM {{ ref('fact_litiges') }}
),

tx_par_client AS (
    SELECT
        client_id,
        segment_client,
        anciennete_jours,
        categorie_anciennete,

        COUNT(transaction_id) AS nb_transactions,
        SUM(montant_eur)      AS montant_total_eur,
        AVG(score_risque)     AS score_risque_moyen
    FROM fact_tx
    GROUP BY client_id, segment_client, anciennete_jours, categorie_anciennete
),

lt_par_client AS (
    SELECT
        client_id,
        COUNT(litige_id)                                       AS nb_litiges,
        SUM(montant_concerne_eur)                              AS montant_total_litiges_eur,
        AVG(montant_concerne_eur)                              AS montant_moyen_litige_eur,
        SUM(CASE WHEN issue = 'defavorable' THEN 1 ELSE 0 END) AS nb_litiges_defavorables,
        SUM(CASE WHEN issue = 'favorable'   THEN 1 ELSE 0 END) AS nb_litiges_favorables
    FROM fact_lt
    GROUP BY client_id
)

SELECT
    t.client_id,
    t.segment_client,
    t.anciennete_jours,
    t.categorie_anciennete,

    t.nb_transactions,
    t.montant_total_eur,
    t.score_risque_moyen,

    COALESCE(l.nb_litiges, 0)                AS nb_litiges,
    COALESCE(l.montant_total_litiges_eur, 0) AS montant_total_litiges_eur,
    COALESCE(l.montant_moyen_litige_eur, 0)  AS montant_moyen_litige_eur,
    COALESCE(l.nb_litiges_defavorables, 0)   AS nb_litiges_defavorables,
    COALESCE(l.nb_litiges_favorables, 0)     AS nb_litiges_favorables,

    ROUND(
        COALESCE(l.nb_litiges, 0) /
        NULLIF(t.nb_transactions, 0) * 100, 2
    ) AS taux_litige_reel_pct

FROM tx_par_client t
LEFT JOIN lt_par_client l ON t.client_id = l.client_id
-- Mart principal : analyse des litiges
-- Répond à l'axe 3 de l'énoncé
-- Granularité : 1 ligne par litige (table de détail)

WITH fact_lt AS (
    SELECT * FROM {{ ref('fact_litiges') }}
)

SELECT
    -- Identifiants
    litige_id,
    transaction_id,
    client_id,

    -- Litige
    type_litige,
    montant_concerne_eur,
    date_litige,
    issue,
    est_defavorable,
    jours_apres_transaction,

    -- Transaction associée
    montant_transaction_eur,
    categorie_device,
    statut_transaction,
    score_risque,
    est_haut_risque,

    -- Géo
    pays,
    ville,
    proxy_vpn_detecte,
    risque_pays,
    est_contexte_risque,

    -- Client
    segment_client,
    categorie_anciennete,
    taux_litiges_pct
    

FROM fact_lt
ORDER BY date_litige DESC
-- Question : Quel quartile de nouveaux clients présente le taux de litige le plus élevé ?

WITH clients AS (
    SELECT * FROM {{ ref('base_crm_clients_staging') }}
),

transactions AS (
    SELECT * FROM {{ ref('transactions_staging') }}
),

litiges AS (
    SELECT * FROM {{ ref('logs_litiges_staging') }}
),

-- Calcul des quartiles d'ancienneté
clients_quartiles AS (
    SELECT
        client_id,
        anciennete_jours,
        taux_litiges_pct,
        segment_client,
        NTILE(4) OVER (ORDER BY anciennete_jours) AS quartile_anciennete
    FROM clients
),

-- Transactions par client
transactions_par_client AS (
    SELECT
        client_id,
        COUNT(transaction_id) AS nb_transactions
    FROM transactions
    GROUP BY client_id
),

-- Litiges par client
litiges_par_client AS (
    SELECT
        client_id,
        COUNT(litige_id) AS nb_litiges
    FROM litiges
    GROUP BY client_id
)

SELECT
    q.quartile_anciennete,
    CASE q.quartile_anciennete
        WHEN 1 THEN 'Q1 — Très nouveaux (0-90j)'
        WHEN 2 THEN 'Q2 — Nouveaux (90-365j)'
        WHEN 3 THEN 'Q3 — Établis (365-730j)'
        WHEN 4 THEN 'Q4 — Fidèles (730j+)'
    END                                                     AS label_quartile,
    COUNT(q.client_id)                                      AS nb_clients,
    AVG(q.anciennete_jours)                                 AS anciennete_moyenne_jours,
    SUM(COALESCE(l.nb_litiges, 0))                          AS nb_litiges_total,
    SUM(COALESCE(t.nb_transactions, 0))                     AS nb_transactions_total,
    ROUND(
        SUM(COALESCE(l.nb_litiges, 0)) /
        NULLIF(SUM(COALESCE(t.nb_transactions, 0)), 0) * 100, 2
    )                                                       AS taux_litige_pct,
    AVG(q.taux_litiges_pct)                                 AS taux_litige_historique_moyen
FROM clients_quartiles q
LEFT JOIN transactions_par_client t ON q.client_id = t.client_id
LEFT JOIN litiges_par_client l      ON q.client_id = l.client_id
GROUP BY q.quartile_anciennete
ORDER BY q.quartile_anciennete
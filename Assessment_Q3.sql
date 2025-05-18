WITH LatestInflowDates AS (
    -- Find the most recent inflow transaction date for each plan
    SELECT
        plan_id,
        MAX(created_on) AS latest_inflow_date
    FROM savings_savingsaccount
    WHERE confirmed_amount > 0 -- Filter for inflow transactions
    GROUP BY plan_id
)
-- Select plans that meet the inactivity criteria
SELECT
    p.id AS plan_id,
    p.owner_id,
    -- Determine the plan type based on the flags provided in hints
    CASE
        WHEN p.is_regular_savings = 1 THEN 'Savings'
        WHEN p.is_a_fund = 1 THEN 'Investment' -- Assuming is_a_fund indicates investment plans
        ELSE 'Other' -- Categorize any other plan types
    END AS type,
    lid.latest_inflow_date AS last_transaction_date,
    ROUND(DATEDIFF(curdate(), coalesce(lid.latest_inflow_date))) AS inactivity_days
FROM plans_plan p
LEFT JOIN LatestInflowDates lid ON p.id = lid.plan_id
WHERE
    lid.latest_inflow_date IS NULL
    OR datediff(curdate(), coalesce(lid.latest_inflow_date)) > 365
ORDER BY inactivity_days DESC;
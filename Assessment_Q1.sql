
WITH FundedPlanMetrics AS (
    SELECT
        p.owner_id,
        COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN p.id ELSE NULL END) AS savings_count,
        COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN p.id ELSE NULL END) AS investment_count,
        -- Sum the confirmed amounts for all plans belonging to the owner
        -- confirmed_amount represents inflow transactions in kobo
        -- Divide by 100 to convert into Naira
        ROUND(SUM(sa.confirmed_amount)/100,2) AS total_deposits
    FROM plans_plan p
    -- Join with savings_savingsaccount to link plans to deposit transactions
    JOIN savings_savingsaccount sa ON p.id = sa.plan_id
    -- Filter for transactions that confirmed_amount > 0
    WHERE sa.confirmed_amount > 0
    -- Group by owner to aggregate metrics per customer
    GROUP BY p.owner_id
)
-- Final selection to get customer details and filtered metrics
SELECT
    cpm.owner_id,
    concat_ws(u.first_name , u.last_name) AS name,
    cpm.savings_count,
    cpm.investment_count,
    cpm.total_deposits
FROM FundedPlanMetrics cpm
JOIN users_customuser u ON cpm.owner_id = u.id
WHERE cpm.savings_count > 0 AND cpm.investment_count > 0
ORDER BY cpm.total_deposits DESC;
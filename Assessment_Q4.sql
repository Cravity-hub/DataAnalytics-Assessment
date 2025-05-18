WITH CustomerActivity AS (
    SELECT
        u.id AS customer_id,
        concat_ws(u.first_name, u.last_name) AS name,
        u.created_on AS signup_date,
        COUNT(sa.id) AS total_transactions,
        SUM(sa.confirmed_amount) AS total_inflow_value
    FROM users_customuser u
    -- Join with plans to link users to their plans
    JOIN plans_plan p ON u.id = p.owner_id
    -- Join with savings_savingsaccount to get transaction details for those plans
    JOIN savings_savingsaccount sa ON p.id = sa.plan_id
    WHERE sa.confirmed_amount > 0 -- Filter to include only inflow transactions as per likely intent for value
    GROUP BY u.id, name, u.created_on -- Group by customer to aggregate their activity
)
-- Now, calculate the tenure and estimate the CLV for each customer
SELECT
    ca.customer_id,
    ca.name,
	PERIOD_DIFF(DATE_FORMAT(CURDATE(), '%Y%m'), DATE_FORMAT(signup_date, '%Y%m')) AS tenure_months,
    ca.total_transactions,
    ROUND(
        ((ca.total_inflow_value * 0.001 * 12.0) /
        PERIOD_DIFF(DATE_FORMAT(CURDATE(), '%Y%m'), DATE_FORMAT(signup_date, '%Y%m')))/100, 2
    ) AS estimated_clv
FROM CustomerActivity ca
-- Order the results by Estimated CLV from highest to lowest as requested
ORDER BY estimated_clv DESC;
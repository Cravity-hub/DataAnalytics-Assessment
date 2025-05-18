WITH MonthlyTransactions AS (
    -- Calculate the number of savings transactions per customer per month
    SELECT
        p.owner_id,
        DATE_FORMAT(sa.created_on, '%Y-%m') AS month_year, -- Extract Year-Month from transaction date
        COUNT(sa.id) AS transaction_count
    FROM savings_savingsaccount sa
    JOIN plans_plan p ON sa.plan_id = p.id 
    GROUP BY p.owner_id, month_year
),
CustomerAvgFrequency AS (
    -- Calculate the average number of transactions per customer per active month
    SELECT
        owner_id,
        SUM(transaction_count) / COUNT(DISTINCT month_year) AS avg_transactions_per_month
    FROM MonthlyTransactions
    GROUP BY owner_id
),
CustomerFrequencyCategory AS (
    -- Assign a frequency category to each customer based on their average monthly transactions
    SELECT
        owner_id,
        avg_transactions_per_month,
        CASE
            WHEN avg_transactions_per_month >= 10 THEN 'High Frequency'
            WHEN avg_transactions_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
            ELSE 'Low Frequency' -- This captures <= 2
        END AS frequency_category
    FROM CustomerAvgFrequency
)
-- Aggregate the results to count customers and find the average transaction rate per category
SELECT
    frequency_category,
    COUNT(DISTINCT owner_id) AS customer_count, -- Count the number of unique customers in each category
    ROUND(AVG(avg_transactions_per_month), 1) AS avg_transactions_per_month
FROM CustomerFrequencyCategory
GROUP BY frequency_category
ORDER BY
    -- Order the categories for a logical output sequence
    CASE frequency_category
        WHEN 'High Frequency' THEN 1
        WHEN 'Medium Frequency' THEN 2
        WHEN 'Low Frequency' THEN 3
    END;
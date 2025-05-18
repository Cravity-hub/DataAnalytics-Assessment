# DataAnalytics-Assessment

This repository contains my solutions for the Data Analyst SQL Proficiency Assessment. The assessment required writing SQL queries to solve specific business problems using a provided MySQL database schema.

## Assessment Overview

In this assessment, I focused on demonstrating SQL skills across various aspects, including data retrieval, filtering, joining multiple tables, aggregation, subqueries/CTEs, date manipulation, and basic calculations for business metrics. The database contained tables related to users, savings accounts (deposits), plans, and withdrawals. My task was to write accurate, efficient, and readable SQL queries for four distinct scenarios.

## Solution Details

Here I explain my approach to each question and any challenges I encountered along the way.

### Question 1: High-Value Customers with Multiple Products


*   #### **My Approach:**
    I started by identifying which tables were needed: `users_customuser` for customer names, `plans_plan` to distinguish plan types and link to the owner, and `savings_savingsaccount` to find deposit transactions and their values - `confirmed_amount`.

    I used a Common Table Expression (CTE), `FundedPlanMetrics`, to aggregate the necessary data at the customer level (`owner_id`). Inside the CTE, I joined `plans_plan` with `savings_savingsaccount` on `plan_id`. I filtered `savings_savingsaccount` for `confirmed_amount > 0` to ensure I was only considering "funded" plans or inflow transactions.

    I then used `COUNT(DISTINCT CASE WHEN ... THEN ... END)` expressions within the aggregation to count funded savings plans (`is_regular_savings = 1`) and funded investment plans (`is_a_fund = 1`) separately for each customer. I also calculated the `SUM(sa.confirmed_amount)` to get the total deposits per customer.

    Finally, in the main query, I joined the `FundedPlanMetrics` CTE with `users_customuser` to retrieve the customer's name. The key filtering step was applying `WHERE cpm.savings_count > 0 AND cpm.investment_count > 0` to select only customers who qualified by having at least one of each type of funded plan. I ordered the final result by `total_deposits` in descending order as requested.

*   #### **Challenges:**
    The main challenge here was ensuring I correctly interpreted "funded" and how to count plan types accurately *while also* aggregating the total deposits. Using `COUNT(DISTINCT CASE ...)` was crucial for getting the count of *types* of funded plans per customer, rather than just counting transactions or total plans. The CTE helped to first consolidate the plan and deposit data per customer before applying the final filters and joins for the output format. Remembering that `confirmed_amount` was in kobo was important for interpreting the `total_deposits` value.

### Question 2: Transaction Frequency Analysis


*   #### **My Approach:**
    This required a multi-step aggregation process, which I handled using multiple CTEs.

    First, I needed to count transactions per customer per *month*. I joined `savings_savingsaccount` with `plans_plan` to link transactions back to `owner_id`. I used `DATE_FORMAT(sa.created_on, '%Y-%m')` to group transactions into monthly buckets for each customer. This resulted in the `MonthlyTransactions` CTE.

    Next, I needed the *average* monthly transaction count *per customer*. I took the results from `MonthlyTransactions` and grouped by `owner_id`. I calculated the average by summing their monthly counts and dividing by the count of distinct months they had transactions. This gave me the `CustomerAvgFrequency` CTE.
    Then, I categorized each customer based on this average using a `CASE` statement, creating the `CustomerFrequencyCategory` CTE.

    Finally, I needed to aggregate the results by the `frequency_category`. I grouped the `CustomerFrequencyCategory` CTE by category, counted the distinct customers in each category (`COUNT(DISTINCT owner_id)`), and calculated the average of the individual customer averages within that category (`AVG(avg_transactions_per_month)`). I rounded the final average as requested and ordered the categories logically using another `CASE` statement in the `ORDER BY` clause.

*   #### **Challenges:**
    One key challenge I faced was correctly interpreting "average number of transactions per customer per month". It doesn't mean total transactions divided by total months across all customers, but rather the average of each *customer's* monthly transaction counts. The multi-stage aggregation using CTEs was essential for breaking down this calculation: 
    
    calculate per customer per month -> calculate average per customer -> categorize per customer -> aggregate results per category.
    
    Handling potential SQL dialect differences in date formatting functions (`DATE_FORMAT` or `STRFTIME`) is always something to consider, but `%Y-%m` is a standard format.

### Question 3: Account Inactivity Alert

*   #### **My Approach:**
    I focused on identifying the *last inflow transaction date* for each plan. I used a CTE, `LatestInflowDates`, to find the maximum `created_at` from the `savings_savingsaccount` table, filtered for `confirmed_amount > 0`, grouped by `plan_id`.

    In the main query, I selected from `plans_plan` and performed a `LEFT JOIN` to the `LatestInflowDates` CTE. A `LEFT JOIN` is crucial here because it includes plans that might *not* have any matching records in `LatestInflowDates`.

    I used a `CASE` statement on `plans_plan` flags (`is_regular_savings`, `is_a_fund`) to determine the plan `type`.

    The filtering logic was based on the `latest_inflow_date` from the CTE. I selected plans where `latest_inflow_date IS NULL` OR where the difference between 'now' and `latest_inflow_date` was greater than 365 days. I calculated the difference in days using `DATE_DIFF()`, which is a robust way to get day differences.

    Finally, I included the calculated date difference as `inactivity_days` and ordered the results by this value.

*   #### **Challenges:**
    The primary challenge was correctly identifying plans that *never* had an inflow transaction. Using a `LEFT JOIN` from `plans_plan` to the aggregated `LatestInflowDates` CTE ensures these plans are included, and checking `latest_inflow_date IS NULL` addresses this case. Correctly calculating the date difference in days and comparing it to 365 was also important; `DATE_DIFF()` is a reliable function for this. Ensuring I filtered specifically for *inflow* transactions (`confirmed_amount > 0`) was key to meeting the "no inflow transactions" requirement.

### Question 4: Customer Lifetime Value (CLV) Estimation

*   #### **My Approach:**
    This required calculating customer tenure and aggregating their transaction value. I joined `users_customuser` with `plans_plan` and `savings_savingsaccount` 

    I used a CTE, `CustomerActivity`, to group the `savings_savingsaccount` data by `owner_id` (linked via `plan_id`), joining it with `users_customuser` to get the `signup_date`. I filtered for `sa.confirmed_amount > 0` as the prompt specified "transaction value" relative to profit per transaction, implying inflow value is the basis. I aggregated `COUNT(sa.id)` for `total_transactions` and `SUM(sa.confirmed_amount)` for `total_inflow_value` per customer.

    In the final select statement, I calculated `tenure_months` using date difference functions comparing 'now' to `signup_date`. I used `DATE_FORMAT() AND PERIOD_DIFF()` functions to extract year and month and calculate the difference in months.

    I then applied the CLV formula. The prompt's formula `(total_transactions / tenure) * 12 * avg_profit_per_transaction` with profit being 0.1% of *value* is a bit ambiguous. The most logical interpretation for a simplified CLV based on *value* is to use the total inflow value. So, I interpreted the "avg_profit_per_transaction" part as `0.1% of Total Inflow Value`. 
    

    Finally, I ordered the results by `estimated_clv` in descending order.

*   #### **Challenges:**
    The main challenge was interpreting the CLV formula provided, specifically how "avg_profit_per_transaction is 0.1% of the transaction value" fits into the formula structure `(total_transactions / tenure) * 12 * avg_profit_per_transaction`. I deduced that the intention was likely `(Total Inflow Value * 0.001 / tenure_months) * 12`, assuming profit is a percentage of the inflow value, which makes more business sense for CLV based on revenue/inflow.


---

This concludes my assessment submission. I have provided the SQL queries in the specified files and detailed my thought process and challenges in this README.

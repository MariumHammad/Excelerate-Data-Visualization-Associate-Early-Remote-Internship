
--Data Validation for Looker Studio:

-- 1. KPI - Total calls:

SELECT 
  COUNT(*) AS total_calls
FROM master_table
WHERE reference_id IS NOT NULL;


-- 2. KPI - Connected Calls:

SELECT 
    COUNT(*) AS connected_calls
FROM master_table
WHERE outcome_1 = 'Connected';


--3. KPI - Not Connected Calls:

SELECT 
    COUNT(reference_id) AS not_connected_calls
FROM master_table
WHERE outcome_1 = 'Not Connected';


--4. KPI 4 — Connectivity Rate (%):

SELECT 
    ROUND(
        COUNT(*) FILTER (WHERE outcome_1 = 'Connected')::DECIMAL 
        / COUNT(*) * 100, 
        2
    ) AS connectivity_rate_percent
FROM master_table;


--📊 CHART 1 -Campaign-wise Call Volume:
------- Table of All Fields----
SELECT 
    campaign_name AS Campaign_Name,
    outcome_1 AS Outcome,
    applicant_country AS Applicant_Country,
    COUNT(reference_id) AS reference_id_count
FROM master_table
GROUP BY
    campaign_name,
    outcome_1,
    applicant_country
ORDER BY
    reference_id_count DESC;


-- Drill down of Each Question ofEach field:
--1️⃣ Campaign-wise count Visualization of Top-10 Campaign:

--Question answered: Which campaigns have the most records?

SELECT 
    applicant_country AS Applicant_Country,
    COUNT(reference_id) AS reference_id_count
FROM master_table
GROUP BY applicant_country
ORDER BY reference_id_count DESC
LIMIT 10;

SELECT 
    campaign_name AS Campaign_Name,
    COUNT(reference_id) AS reference_id_count
FROM master_table
GROUP BY campaign_name
ORDER BY reference_id_count DESC;

----2️⃣ Outcome-wise count Visualization of Top 10 Outcomes:

-----Question answered: How many records per outcome?


SELECT 
    applicant_country AS Applicant_Country,
    COUNT(reference_id) AS reference_id_count
FROM master_table
GROUP BY applicant_country
ORDER BY reference_id_count DESC
LIMIT 10;

SELECT 
    outcome_1 AS Outcome,
    COUNT(reference_id) AS reference_id_count
FROM master_table
GROUP BY outcome_1
ORDER BY reference_id_count DESC;

-- 3️⃣ Country-wise count Visualization of Top 10 Countries:
--Question answered: Which countries have the highest number of applicants?
SELECT 
    applicant_country AS Applicant_Country,
    COUNT(reference_id) AS reference_id_count
FROM master_table
GROUP BY applicant_country
ORDER BY reference_id_count DESC
LIMIT 10;

SELECT 
    applicant_country AS Applicant_Country,
    COUNT(reference_id) AS reference_id_count
FROM master_table
GROUP BY applicant_country;


--📊 CHART 2 - Call Outcome Distribution Visulaization:

SELECT
    outcome_1 AS Call_Outcome,
    COUNT(reference_id) AS call_count
FROM master_table
GROUP BY outcome_1
ORDER BY call_count DESC;

--📊 CHART 3 -Category Distribution (Campaign-wise):

SELECT
    campaign_name AS Category,
    COUNT(reference_id) AS call_count
FROM master_table
GROUP BY campaign_name
ORDER BY call_count DESC;


-- Chart 4 - Top Connected Calls of Agents:

SELECT
    caller_name AS Agent_Name,
    COUNT(reference_id) AS connected_calls
FROM master_table
WHERE outcome_1 = 'Connected'
GROUP BY caller_name
ORDER BY connected_calls DESC;


--- Chart 5 - Call Outcome Distribution Table Visualization:

SELECT
    caller_name AS agent_name,

    COUNT(*) AS outcome_cleaned,

    -- Total Calls (K format)
    CASE
        WHEN COUNT(*) >= 1000
            THEN ROUND(COUNT(*) / 1000.0, 1) || 'K'
        ELSE COUNT(*)::TEXT
    END AS total_calls,

    -- Connected Calls
    COUNT(CASE WHEN outcome_1 = 'Connected' THEN 1 END) AS connected_calls,

    -- Not Connected Calls (K format)
    CASE
        WHEN COUNT(CASE WHEN outcome_1 <> 'Connected' THEN 1 END) >= 1000
            THEN ROUND(
                COUNT(CASE WHEN outcome_1 <> 'Connected' THEN 1 END) / 1000.0,
                1
            ) || 'K'
        ELSE COUNT(CASE WHEN outcome_1 <> 'Connected' THEN 1 END)::TEXT
    END AS not_connected_calls,

    -- Connectivity Rate (same logic as Looker Studio)
    ROUND(
        COUNT(CASE WHEN outcome_1 = 'Connected' THEN 1 END)
        * 1.0
        / COUNT(*),
        4
    ) AS connectivity_rate,

    COUNT(CASE WHEN outcome_1 = 'Completed Application' THEN 1 END) AS completed_application,
    COUNT(CASE WHEN outcome_1 = 'Reschedule' THEN 1 END) AS reschedule,
    COUNT(CASE WHEN outcome_1 = 'Will Submit Docs' THEN 1 END) AS will_submit_docs

FROM master_table
WHERE caller_name IS NOT NULL
GROUP BY caller_name
ORDER BY COUNT(*) DESC;






--📊 CHART 6 - Agent Performance: 

SELECT
    caller_name AS Agent_Name,
    COUNT(CASE WHEN outcome_1 = 'Connected' THEN 1 END) AS connected_calls,
    COUNT(CASE WHEN outcome_1 = 'Not Connected' THEN 1 END) AS not_connected_calls
FROM master_table
GROUP BY caller_name
ORDER BY connected_calls DESC, not_connected_calls DESC;













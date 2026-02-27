-- 1. Creating the tables and importing the data 
CREATE TABLE applicant_data (
    app_id VARCHAR,
    country VARCHAR,
    university VARCHAR,
    phone_number VARCHAR
);

CREATE TABLE outreach_data (
    reference_id VARCHAR,
    received_at VARCHAR,
    university VARCHAR,
    caller_name VARCHAR,
    outcome_1 VARCHAR,
    remark VARCHAR,
    campaign_id VARCHAR,
    escalation_required VARCHAR
);

CREATE TABLE campaign_data (
    id VARCHAR,
    name VARCHAR,
    category VARCHAR,
    intake VARCHAR,
    university VARCHAR,
    status VARCHAR,
    start_date VARCHAR
);

-- 2. Checking the table after loading
SELECT * FROM applicant_data LIMIT 5;

-- 3. Count Rows 
SELECT COUNT(*) FROM applicant_data;
SELECT COUNT(*) FROM outreach_data;
SELECT COUNT(*) FROM campaign_data;

-- 4. Convert Date Columns in outreach and campaign data
UPDATE outreach_data
SET received_at = TO_TIMESTAMP('2025-12-05 17:53:34', 'YYYY-MM-DD HH24:MI:SS');


UPDATE public.campaign_data
SET start_date = TO_DATE(LEFT('2024-11-25 Main St', 10), 'YYYY-MM-DD');

-- 5. Exploratory Data Analysis
--These SQL queries will help you check completeness, consistency, outliers, and trends

-- Exploratory Analysis
--  Check Row Counts
SELECT COUNT(*) AS applicant_rows FROM applicant_data;
SELECT COUNT(*) AS outreach_rows FROM outreach_data;
SELECT COUNT(*) AS campaign_rows FROM campaign_data;

-- Check Missing Values
-- Applicant:
SELECT
  COUNT(*) FILTER (WHERE app_id IS NULL OR app_id = '') AS missing_app_id,
  COUNT(*) FILTER (WHERE country IS NULL) AS missing_country,
  COUNT(*) FILTER (WHERE university IS NULL) AS missing_university,
  COUNT(*) FILTER (WHERE phone_number IS NULL OR phone_number = '') AS missing_phone
FROM applicant_data;

-- Outreach:
SELECT
  COUNT(*) FILTER (WHERE reference_id IS NULL) AS missing_reference_id,
  COUNT(*) FILTER (WHERE received_at IS NULL) AS missing_received_at,
  COUNT(*) FILTER (WHERE outcome_1 IS NULL OR outcome_1 = '') AS missing_outcome
FROM outreach_data;

-- Campaign:
SELECT
  COUNT(*) FILTER (WHERE id IS NULL) AS missing_campaign_id,
  COUNT(*) FILTER (WHERE start_date IS NULL) AS missing_start_date
FROM campaign_data;

-- Check Duplicates
-- Applicant:
SELECT app_id, COUNT(*)
FROM applicant_data
GROUP BY app_id
HAVING COUNT(*) > 1;

-- Outreach:
SELECT reference_id, COUNT(*)
FROM outreach_data
GROUP BY reference_id
HAVING COUNT(*) > 1;

-- Campaign:
SELECT id, COUNT(*)
FROM campaign_data
GROUP BY id
HAVING COUNT(*) > 1;

-- Detect Outliers (Phone Numbers)
SELECT phone_number
FROM applicant_data
WHERE LENGTH(phone_number) <> 10;

Select * From public.applicant_data;


-- Distribution of Applicants by Country
SELECT country, COUNT(*) 
FROM applicant_data
GROUP BY country
ORDER BY COUNT(*) DESC;

-- Outreach Outcome Distribution
SELECT outcome_1, COUNT(*)
FROM outreach_data
GROUP BY outcome_1
ORDER BY COUNT(*) DESC;

-- Campaigns by Category
SELECT category, COUNT(*)
FROM campaign_data
GROUP BY category;

-- DATA CLEANING SQL:
-- Remove Duplicate Applicants:
DELETE FROM applicant_data a
USING applicant_data b
WHERE a.ctid < b.ctid
AND a.app_id = b.app_id;

-- Standardize Text (fix capitalization & whitespace)
--Applicant:
UPDATE applicant_data
SET country = INITCAP(TRIM(country)),
    university = INITCAP(TRIM(university));

-- Outreach:
UPDATE outreach_data
SET outcome_1 = INITCAP(TRIM(outcome_1)),
    caller_name = INITCAP(TRIM(caller_name));

-- Campaign:
UPDATE campaign_data
SET category = INITCAP(TRIM(category)),
    status = INITCAP(TRIM(status));

-- Fix Missing/Blank Values:
-- Replace missing outcomes:
UPDATE outreach_data
SET outcome_1 = 'Unknown'
WHERE outcome_1 IS NULL OR outcome_1 = '';

-- Replace missing phone numbers:
UPDATE applicant_data
SET phone_number = NULL
WHERE phone_number = '';


-- Dealing with phone number length
-- Remove Non-Numeric Characters:
UPDATE applicant_data
SET phone_number = regexp_replace(phone_number, '[^0-9]', '', 'g');

-- Fix Country Code “91” or “+91” Prefixes
UPDATE applicant_data
SET phone_number = RIGHT(phone_number, 10)
WHERE LENGTH(phone_number) > 10;

-- Handle Too-Short Numbers (< 10 digits
UPDATE applicant_data
SET phone_number = NULL
WHERE LENGTH(phone_number) < 10;

-- Final Validation Check
SELECT 
    COUNT(*) FILTER (WHERE phone_number IS NULL) AS null_numbers,
    COUNT(*) FILTER (WHERE LENGTH(phone_number) <> 10 AND phone_number IS NOT NULL) AS invalid_length,
    COUNT(*) FILTER (WHERE LENGTH(phone_number) = 10) AS valid_numbers
FROM applicant_data;

-- Convert Dates Permanently
-- Outreach:
ALTER TABLE outreach_data
ALTER COLUMN received_at TYPE TIMESTAMP USING received_at::timestamp;

-- Campaign:
ALTER TABLE campaign_data
ALTER COLUMN start_date TYPE DATE USING start_date::date;

-- Dealing with anomalies in Country column:
-- Country cleaning script for applicant_data
-- BACKUP + CLEAN + VALIDATION
BEGIN;

-- 1) Basic normalize: trim whitespace and convert empty strings to NULL
UPDATE applicant_data
SET country = NULLIF(TRIM(country), '');

-- 2) Remove obvious non-country entries
-- 2.1 emails => NULL
UPDATE applicant_data
SET country = NULL
WHERE country LIKE '%@%';

-- 2.2 obvious long descriptive responses or non-country sentences => NULL
UPDATE applicant_data
SET country = NULL
WHERE country ILIKE 'not attending%' OR country ILIKE '%going to a higher%' OR country ILIKE '%not attending illinois%' OR country ILIKE '%going to a higher%';

-- 2.3 entries that mention "University" or "College" or obvious phrases => NULL
UPDATE applicant_data
SET country = NULL
WHERE country ILIKE '%univer%' OR country ILIKE '%college%' OR country ILIKE '%institute%';

-- 3) Handle multi-country / comma-separated values: set to NULL (safe approach)
--    If you prefer to keep the first country, we can change this behavior later.
UPDATE applicant_data
SET country = NULL
WHERE country LIKE '%,%';

-- 4) Specific common-correction mappings (normalize common variations)
-- 4.1 Congo variants -> Democratic Republic of the Congo
UPDATE applicant_data
SET country = 'Democratic Republic of the Congo'
WHERE country ILIKE '%democratic republic of the congo%' 
   OR country ILIKE '%congo, the democratic republic of the%'
   OR country ILIKE '%congo drc%'
   OR (country ILIKE '%congo%' AND country NOT ILIKE '%republic of the congo%');

-- 4.2 Cote d'Ivoire variants (including bad encoding) -> Côte d'Ivoire
UPDATE applicant_data
SET country = 'Côte d''Ivoire'
WHERE country ILIKE 'cote d%ivoire%' OR country ILIKE 'c�te d%ivoire%' OR country ILIKE '%ivoir%';

-- 4.3 Other likely mappings (add/edit these as you inspect distinct list)
UPDATE applicant_data SET country = 'United States' WHERE country ILIKE 'usa' OR country ILIKE 'us' OR country ILIKE 'united states%';
UPDATE applicant_data SET country = 'United Kingdom' WHERE country ILIKE 'uk' OR country ILIKE 'united kingdom%';
UPDATE applicant_data SET country = 'South Korea' WHERE country ILIKE 'korea, south' OR country ILIKE 'south korea%';

-- 5) Remove values containing digits or stray special characters (not country names)
UPDATE applicant_data
SET country = NULL
WHERE country ~ '[0-9]';

-- 6) Remove entries composed mostly of non-letter characters (safety)
UPDATE applicant_data
SET country = NULL
WHERE country ~ '^[^[:alpha:]]+$';

-- 7) Final simple normalization for remaining non-NULL values
--    Trim again, replace multiple spaces, and set to Title Case (INITCAP)
UPDATE applicant_data
SET country = INITCAP(REGEXP_REPLACE(TRIM(country), '\s+', ' ', 'g'))
WHERE country IS NOT NULL;

-- 8) Final validation summary (run and review the output)
--    This SELECT returns counts you can paste into your report.
--    If the results look good, COMMIT below; otherwise ROLLBACK.
SELECT
  COUNT(*) FILTER (WHERE country IS NULL)         AS null_country,
  COUNT(*) FILTER (WHERE country !~ '^[[:alpha:][:space:].''-]+$' AND country IS NOT NULL) AS suspicious_after,
  COUNT(*) FILTER (WHERE country ~ '^[[:alpha:][:space:].''-]+$') AS valid_country
FROM applicant_data;

-- Optional: show top countries for inspection (edit LIMIT as needed)
SELECT country, COUNT(*) AS cnt
FROM applicant_data
WHERE country IS NOT NULL
GROUP BY country
ORDER BY cnt DESC
LIMIT 50;


-- Dealing with anomalies in reference id in outreach dataset
--  Detect and count invalid Reference_ID values
SELECT 
    COUNT(*) FILTER (WHERE reference_id IS NULL) AS null_ids,
    COUNT(*) FILTER (WHERE reference_id !~ '^[0-9]+$' AND reference_id IS NOT NULL) AS non_numeric_ids,
    COUNT(*) FILTER (WHERE reference_id ~ '^[0-9]+$') AS numeric_ids
FROM outreach_data;

--  Set invalid formats (non-numeric or garbage values) to NULL
UPDATE outreach_data
SET reference_id = NULL
WHERE reference_id IS NULL
   OR reference_id !~ '^[0-9]+$';

-- Set numeric but NON-MATCHING IDs (not found in applicant_data) to NULL
UPDATE outreach_data o
SET reference_id = NULL
WHERE reference_id IS NOT NULL
  AND NOT EXISTS (
        SELECT 1 
        FROM applicant_data a
        WHERE a.app_id = o.reference_id
    );

-- Final validation: show remaining invalid values (should be zero or null)
SELECT DISTINCT reference_id
FROM outreach_data
WHERE reference_id IS NULL
   OR reference_id !~ '^[0-9]+$'
ORDER BY reference_id;


-- Creating a master table suitable for data visualization
DROP TABLE IF EXISTS master_table;
CREATE TABLE master_table AS
SELECT
    o.reference_id,
    o.received_at,
    o.caller_name,
    o.outcome_1,
    o.remark,
    o.campaign_id,
    o.escalation_required,

    a.app_id,
    a.country AS applicant_country,
    a.university AS applicant_university,
    a.phone_number AS applicant_phone,

    c.name AS campaign_name,
    c.category AS campaign_category,
    c.intake AS campaign_intake,
    c.status AS campaign_status,
    c.start_date AS campaign_start_date

FROM outreach_data o
LEFT JOIN applicant_data a 
    ON o.reference_id = a.app_id
LEFT JOIN campaign_data c
    ON o.campaign_id = c.id;



SELECT *
FROM master_table
LIMIT 10;

SELECT column_name
FROM information_schema.columns
WHERE table_name = 'master_table';

SELECT COUNT(*) FROM master_table;


COMMIT;





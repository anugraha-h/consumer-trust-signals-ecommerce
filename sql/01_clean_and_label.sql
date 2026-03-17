-- ============================================================
-- Project: Consumer Trust Signals in Fashion E-Commerce
-- Phase 1: Data Cleaning & Trust Label Engineering
-- Dataset: Women's E-Commerce Clothing Reviews (Kaggle)
-- ============================================================


-- ============================================================
-- STEP 1: Create the raw table to load your CSV into
-- ============================================================

CREATE TABLE IF NOT EXISTS raw_reviews (
    clothing_id       INTEGER,
    age               INTEGER,
    title             TEXT,
    review_text       TEXT,
    rating            INTEGER,
    recommended_ind   INTEGER,
    positive_feedback_count INTEGER,
    division_name     TEXT,
    department_name   TEXT,
    class_name        TEXT
);


-- ============================================================
-- STEP 2: Inspect the data
-- ============================================================

-- Check total rows
SELECT COUNT(*) AS total_rows FROM raw_reviews;

-- Check for nulls in key columns
SELECT
    COUNT(*) AS total,
    SUM(CASE WHEN review_text IS NULL OR TRIM(review_text) = '' THEN 1 ELSE 0 END) AS null_reviews,
    SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END) AS null_ratings,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS null_ages
FROM raw_reviews;

-- Rating distribution
SELECT rating, COUNT(*) AS count
FROM raw_reviews
GROUP BY rating
ORDER BY rating;

-- Department breakdown
SELECT department_name, COUNT(*) AS count
FROM raw_reviews
GROUP BY department_name
ORDER BY count DESC;


-- ============================================================
-- STEP 3: Clean and label — create analysis-ready table
-- ============================================================

CREATE TABLE IF NOT EXISTS clean_reviews AS
SELECT
    ROW_NUMBER() OVER () AS review_id,

    -- Age banding
    age,
    CASE
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 35 THEN '26-35'
        WHEN age BETWEEN 36 AND 50 THEN '36-50'
        WHEN age > 50             THEN '50+'
        ELSE 'Unknown'
    END AS age_band,

    department_name,
    class_name,
    TRIM(review_text) AS review_text,
    rating,
    recommended_ind,
    positive_feedback_count,

    -- Trust label: high trust = rating >= 4 AND recommended
    CASE
        WHEN rating >= 4 AND recommended_ind = 1 THEN 1
        ELSE 0
    END AS trust_label

FROM raw_reviews
WHERE
    review_text IS NOT NULL
    AND TRIM(review_text) != ''
    AND rating IS NOT NULL;


-- ============================================================
-- STEP 4: Validate the output
-- ============================================================

-- Row count after cleaning
SELECT COUNT(*) AS clean_rows FROM clean_reviews;

-- Trust label balance
SELECT
    trust_label,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM clean_reviews
GROUP BY trust_label;

-- Avg rating and trust rate by department
SELECT
    department_name,
    COUNT(*)                          AS total_reviews,
    ROUND(AVG(rating), 2)             AS avg_rating,
    ROUND(AVG(recommended_ind), 2)    AS recommendation_rate,
    ROUND(AVG(trust_label), 2)        AS trust_rate
FROM clean_reviews
GROUP BY department_name
ORDER BY trust_rate DESC;

-- Trust rate by age band
SELECT
    age_band,
    COUNT(*)                    AS total_reviews,
    ROUND(AVG(trust_label), 2)  AS trust_rate
FROM clean_reviews
GROUP BY age_band
ORDER BY trust_rate DESC;

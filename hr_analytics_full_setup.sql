-- ================================================================
--  HR_Analytics  |  Full Database Setup Script
--  Project : AI Agent for Relational Database System
--  Dataset : IBM HR Analytics (synthetic, 1470 rows per table)
--  Author  : DB / SQL Team
-- ================================================================
--  HOW TO RUN:
--  1. Open MySQL Workbench
--  2. File → Open SQL Script → select this file
--  3. Press Ctrl+Shift+Enter  (Run All)
--  4. Wait ~30 seconds for data generation to finish
-- ================================================================


-- ================================================================
-- STEP 1: Create Database
-- ================================================================
DROP DATABASE IF EXISTS HR_Analytics;
CREATE DATABASE HR_Analytics
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE HR_Analytics;


-- ================================================================
-- STEP 2: Create Tables  (matches your ER Diagram exactly)
-- ================================================================

-- Central entity – all others reference this
CREATE TABLE emp_personal (
    EmployeeNumber   INT          NOT NULL AUTO_INCREMENT,
    Age              INT          NOT NULL,
    Gender           VARCHAR(10)  NOT NULL,
    MaritalStatus    VARCHAR(20)  NOT NULL,
    Education        INT          NOT NULL  COMMENT '1=Below College 2=College 3=Bachelor 4=Master 5=Doctor',
    EducationField   VARCHAR(50)  NOT NULL,
    Over18           VARCHAR(3)   NOT NULL  DEFAULT 'Y',
    DistanceFromHome INT          NOT NULL,
    PRIMARY KEY (EmployeeNumber)
);

CREATE TABLE emp_job_details (
    EmployeeNumber    INT          NOT NULL,
    Department        VARCHAR(50)  NOT NULL,
    BusinessTravel    VARCHAR(50)  NOT NULL,
    JobRole           VARCHAR(50)  NOT NULL,
    JobLevel          INT          NOT NULL  COMMENT '1-5',
    OverTime          VARCHAR(3)   NOT NULL  COMMENT 'Yes/No',
    EmployeeCount     INT          NOT NULL  DEFAULT 1,
    PerformanceRating INT          NOT NULL  COMMENT '3=Excellent 4=Outstanding',
    StandardHours     INT          NOT NULL  DEFAULT 80,
    PRIMARY KEY (EmployeeNumber),
    FOREIGN KEY (EmployeeNumber) REFERENCES emp_personal(EmployeeNumber) ON DELETE CASCADE
);

CREATE TABLE emp_financial (
    EmployeeNumber    INT NOT NULL,
    MonthlyIncome     INT NOT NULL,
    MonthlyRate       INT NOT NULL,
    DailyRate         INT NOT NULL,
    HourlyRate        INT NOT NULL,
    PercentSalaryHike INT NOT NULL,
    StockOptionLevel  INT NOT NULL  COMMENT '0-3',
    PRIMARY KEY (EmployeeNumber),
    FOREIGN KEY (EmployeeNumber) REFERENCES emp_personal(EmployeeNumber) ON DELETE CASCADE
);

CREATE TABLE emp_feedback (
    EmployeeNumber           INT NOT NULL,
    EnvironmentSatisfaction  INT NOT NULL  COMMENT '1=Low 2=Medium 3=High 4=Very High',
    JobInvolvement           INT NOT NULL  COMMENT '1-4',
    JobSatisfaction          INT NOT NULL  COMMENT '1-4',
    RelationshipSatisfaction INT NOT NULL  COMMENT '1-4',
    WorkLifeBalance          INT NOT NULL  COMMENT '1=Bad 2=Good 3=Better 4=Best',
    PRIMARY KEY (EmployeeNumber),
    FOREIGN KEY (EmployeeNumber) REFERENCES emp_personal(EmployeeNumber) ON DELETE CASCADE
);

CREATE TABLE emp_tenure (
    EmployeeNumber          INT         NOT NULL,
    NumCompaniesWorked      INT         NOT NULL,
    TotalWorkingYears       INT         NOT NULL,
    TrainingTimesLastYear   INT         NOT NULL,
    YearsInCompany          INT         NOT NULL,
    YearsInCurrentRole      INT         NOT NULL,
    YearsSinceLastPromotion INT         NOT NULL,
    YearsWithCurrManager    INT         NOT NULL,
    Attrition               VARCHAR(3)  NOT NULL  COMMENT 'Yes/No',
    PRIMARY KEY (EmployeeNumber),
    FOREIGN KEY (EmployeeNumber) REFERENCES emp_personal(EmployeeNumber) ON DELETE CASCADE
);


-- ================================================================
-- STEP 3: Generate 1470 rows of realistic HR data
--         (matching real IBM HR Analytics distribution)
-- ================================================================

DROP PROCEDURE IF EXISTS generate_hr_data;

DELIMITER $$

CREATE PROCEDURE generate_hr_data()
BEGIN
    DECLARE i INT DEFAULT 1;

    -- personal
    DECLARE v_age       INT;
    DECLARE v_gender    VARCHAR(10);
    DECLARE v_marital   VARCHAR(20);
    DECLARE v_edu       INT;
    DECLARE v_edu_field VARCHAR(50);
    DECLARE v_distance  INT;

    -- job
    DECLARE v_dept     VARCHAR(50);
    DECLARE v_role     VARCHAR(50);
    DECLARE v_travel   VARCHAR(50);
    DECLARE v_level    INT;
    DECLARE v_overtime VARCHAR(3);
    DECLARE v_perf     INT;

    -- financial
    DECLARE v_income INT;
    DECLARE v_mrate  INT;
    DECLARE v_drate  INT;
    DECLARE v_hrate  INT;
    DECLARE v_hike   INT;
    DECLARE v_stock  INT;

    -- feedback
    DECLARE v_env_sat INT;
    DECLARE v_job_inv INT;
    DECLARE v_job_sat INT;
    DECLARE v_rel_sat INT;
    DECLARE v_wlb     INT;

    -- tenure
    DECLARE v_companies    INT;
    DECLARE v_total_years  INT;
    DECLARE v_training     INT;
    DECLARE v_yrs_company  INT;
    DECLARE v_yrs_role     INT;
    DECLARE v_yrs_promo    INT;
    DECLARE v_yrs_mgr      INT;
    DECLARE v_attrition    VARCHAR(3);

    WHILE i <= 1470 DO

        -- ── Personal ──────────────────────────────────────────────
        SET v_age       = 18 + FLOOR(RAND() * 42);
        SET v_gender    = IF(RAND() > 0.40, 'Male', 'Female');
        SET v_marital   = ELT(1 + FLOOR(RAND() * 3), 'Single', 'Married', 'Divorced');
        SET v_edu       = 1 + FLOOR(RAND() * 5);
        SET v_edu_field = ELT(1 + FLOOR(RAND() * 6),
                              'Life Sciences','Medical','Marketing',
                              'Technical Degree','Human Resources','Other');
        SET v_distance  = 1 + FLOOR(RAND() * 29);

        -- ── Job ───────────────────────────────────────────────────
        SET v_dept = ELT(1 + FLOOR(RAND() * 3),
                         'Sales', 'Research & Development', 'Human Resources');

        SET v_role = CASE v_dept
            WHEN 'Sales' THEN
                ELT(1 + FLOOR(RAND() * 3),
                    'Sales Executive','Sales Representative','Manager')
            WHEN 'Research & Development' THEN
                ELT(1 + FLOOR(RAND() * 5),
                    'Research Scientist','Laboratory Technician',
                    'Manufacturing Director','Research Director',
                    'Healthcare Representative')
            ELSE
                ELT(1 + FLOOR(RAND() * 2), 'Human Resources','Manager')
        END;

        SET v_travel   = ELT(1 + FLOOR(RAND() * 3),
                             'Travel_Rarely','Travel_Frequently','Non-Travel');
        SET v_level    = 1 + FLOOR(RAND() * 5);
        SET v_overtime = IF(RAND() > 0.72, 'Yes', 'No');   -- ~28 % work overtime
        SET v_perf     = IF(RAND() > 0.15, 3, 4);           -- 85 % Excellent, 15 % Outstanding

        -- ── Financial (income correlated with JobLevel) ────────────
        SET v_income = (v_level * 2500) + 1000 + FLOOR(RAND() * 4000);
        SET v_mrate  = 2000  + FLOOR(RAND() * 22000);
        SET v_drate  = 100   + FLOOR(RAND() * 1300);
        SET v_hrate  = 30    + FLOOR(RAND() * 70);
        SET v_hike   = 10    + FLOOR(RAND() * 16);
        SET v_stock  = FLOOR(RAND() * 4);

        -- ── Feedback ──────────────────────────────────────────────
        SET v_env_sat = 1 + FLOOR(RAND() * 4);
        SET v_job_inv = 1 + FLOOR(RAND() * 4);
        SET v_job_sat = 1 + FLOOR(RAND() * 4);
        SET v_rel_sat = 1 + FLOOR(RAND() * 4);
        SET v_wlb     = 1 + FLOOR(RAND() * 4);

        -- ── Tenure (logically consistent) ─────────────────────────
        SET v_total_years = FLOOR(RAND() * 40);
        SET v_yrs_company = FLOOR(RAND() * (v_total_years + 1));
        SET v_yrs_role    = FLOOR(RAND() * (v_yrs_company + 1));
        SET v_yrs_promo   = FLOOR(RAND() * (v_yrs_company + 1));
        SET v_yrs_mgr     = FLOOR(RAND() * (v_yrs_company + 1));
        SET v_companies   = LEAST(FLOOR(RAND() * 10), v_total_years + 1);
        SET v_training    = FLOOR(RAND() * 7);

        -- Attrition ~16 % (realistic IBM HR rate)
        SET v_attrition = IF(RAND() > 0.84, 'Yes', 'No');

        -- ── Inserts ───────────────────────────────────────────────
        INSERT INTO emp_personal
            (Age, Gender, MaritalStatus, Education, EducationField, Over18, DistanceFromHome)
        VALUES
            (v_age, v_gender, v_marital, v_edu, v_edu_field, 'Y', v_distance);

        INSERT INTO emp_job_details VALUES
            (i, v_dept, v_travel, v_role, v_level, v_overtime, 1, v_perf, 80);

        INSERT INTO emp_financial VALUES
            (i, v_income, v_mrate, v_drate, v_hrate, v_hike, v_stock);

        INSERT INTO emp_feedback VALUES
            (i, v_env_sat, v_job_inv, v_job_sat, v_rel_sat, v_wlb);

        INSERT INTO emp_tenure VALUES
            (i, v_companies, v_total_years, v_training,
             v_yrs_company, v_yrs_role, v_yrs_promo, v_yrs_mgr, v_attrition);

        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

-- Run it (takes ~20-30 seconds)
CALL generate_hr_data();
DROP PROCEDURE IF EXISTS generate_hr_data;


-- ================================================================
-- STEP 4: Data Cleaning
-- ================================================================

-- Ensure non-negative tenure values
UPDATE emp_tenure SET NumCompaniesWorked      = 0 WHERE NumCompaniesWorked      < 0;
UPDATE emp_tenure SET TotalWorkingYears       = 0 WHERE TotalWorkingYears       < 0;
UPDATE emp_tenure SET YearsInCompany          = 0 WHERE YearsInCompany          < 0;
UPDATE emp_tenure SET YearsInCurrentRole      = 0 WHERE YearsInCurrentRole      < 0;
UPDATE emp_tenure SET YearsSinceLastPromotion = 0 WHERE YearsSinceLastPromotion < 0;
UPDATE emp_tenure SET YearsWithCurrManager    = 0 WHERE YearsWithCurrManager    < 0;
UPDATE emp_tenure SET TrainingTimesLastYear   = 0 WHERE TrainingTimesLastYear   < 0;

-- Logical consistency: sub-tenure fields cannot exceed YearsInCompany
UPDATE emp_tenure
SET YearsInCurrentRole = YearsInCompany
WHERE YearsInCurrentRole > YearsInCompany;

UPDATE emp_tenure
SET YearsSinceLastPromotion = YearsInCompany
WHERE YearsSinceLastPromotion > YearsInCompany;

UPDATE emp_tenure
SET YearsWithCurrManager = YearsInCompany
WHERE YearsWithCurrManager > YearsInCompany;

-- Age must be ≥ 18
UPDATE emp_personal SET Age = 18 WHERE Age < 18;

-- Income cannot be negative
UPDATE emp_financial SET MonthlyIncome = 1000 WHERE MonthlyIncome < 1000;

-- Verify cleaning (should return 0 for all)
SELECT 'Negative tenure values remaining' AS check_name,
       SUM(YearsInCurrentRole < 0) + SUM(YearsSinceLastPromotion < 0) AS bad_rows
FROM emp_tenure;

SELECT 'Underage employees' AS check_name,
       COUNT(*) AS bad_rows
FROM emp_personal WHERE Age < 18;


-- ================================================================
-- STEP 5: Indexes  (optimize queries for AI agent analysis)
-- ================================================================

-- emp_job_details — frequently filtered / grouped
CREATE INDEX idx_dept     ON emp_job_details(Department);
CREATE INDEX idx_overtime ON emp_job_details(OverTime);
CREATE INDEX idx_jobrole  ON emp_job_details(JobRole);
CREATE INDEX idx_joblevel ON emp_job_details(JobLevel);

-- emp_tenure — Attrition is queried in every insight
CREATE INDEX idx_attrition   ON emp_tenure(Attrition);
CREATE INDEX idx_yrs_promo   ON emp_tenure(YearsSinceLastPromotion);
CREATE INDEX idx_yrs_company ON emp_tenure(YearsInCompany);

-- emp_personal — demographic filters
CREATE INDEX idx_distance ON emp_personal(DistanceFromHome);
CREATE INDEX idx_marital  ON emp_personal(MaritalStatus);
CREATE INDEX idx_age      ON emp_personal(Age);

-- emp_financial — income aggregations
CREATE INDEX idx_income ON emp_financial(MonthlyIncome);


-- ================================================================
-- STEP 6: VIEWs  (one per problem statement)
-- ================================================================

-- ─────────────────────────────────────────────────────────────────
-- VIEW 1 | High-Value Talent Retention Analysis
--   Problem : Are high-earning employees in certain departments leaving more?
-- ─────────────────────────────────────────────────────────────────
DROP VIEW IF EXISTS view_talent_retention;
CREATE VIEW view_talent_retention AS
SELECT
    j.Department,
    COUNT(*)                                                                  AS TotalEmployees,
    ROUND(AVG(f.MonthlyIncome), 2)                                           AS AvgMonthlyIncome,
    SUM(CASE WHEN t.Attrition = 'Yes' THEN 1 ELSE 0 END)                   AS TotalAttrition,
    ROUND(
        SUM(CASE WHEN t.Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                                                          AS AttritionRate_Pct,
    ROUND(
        AVG(CASE WHEN t.Attrition = 'Yes' THEN f.MonthlyIncome END), 2
    )                                                                          AS AvgIncomeOfLeavers,
    ROUND(
        AVG(CASE WHEN t.Attrition = 'No'  THEN f.MonthlyIncome END), 2
    )                                                                          AS AvgIncomeOfStayers
FROM emp_job_details j
JOIN emp_financial   f ON j.EmployeeNumber = f.EmployeeNumber
JOIN emp_tenure      t ON j.EmployeeNumber = t.EmployeeNumber
GROUP BY j.Department
ORDER BY AvgMonthlyIncome DESC;


-- ─────────────────────────────────────────────────────────────────
-- VIEW 2 | Work-Life Balance & Overtime Correlation
--   Problem : Is overtime destroying work-life balance and morale?
-- ─────────────────────────────────────────────────────────────────
DROP VIEW IF EXISTS view_overtime_satisfaction;
CREATE VIEW view_overtime_satisfaction AS
SELECT
    j.JobRole,
    j.OverTime,
    COUNT(*)                                   AS EmployeeCount,
    ROUND(AVG(fb.WorkLifeBalance),         2)  AS AvgWorkLifeBalance,
    ROUND(AVG(fb.JobSatisfaction),         2)  AS AvgJobSatisfaction,
    ROUND(AVG(fb.JobInvolvement),          2)  AS AvgJobInvolvement,
    ROUND(AVG(fb.EnvironmentSatisfaction), 2)  AS AvgEnvSatisfaction,
    SUM(CASE WHEN t.Attrition = 'Yes' THEN 1 ELSE 0 END)  AS AttritionCount,
    ROUND(
        SUM(CASE WHEN t.Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                           AS AttritionRate_Pct
FROM emp_job_details j
JOIN emp_feedback    fb ON j.EmployeeNumber = fb.EmployeeNumber
JOIN emp_tenure      t  ON j.EmployeeNumber = t.EmployeeNumber
GROUP BY j.JobRole, j.OverTime
ORDER BY j.JobRole, j.OverTime DESC;


-- ─────────────────────────────────────────────────────────────────
-- VIEW 3 | Promotion Stagnation & Performance Link
--   Problem : Do employees without promotions 5+ years disengage?
-- ─────────────────────────────────────────────────────────────────
DROP VIEW IF EXISTS view_promotion_stagnation;
CREATE VIEW view_promotion_stagnation AS
SELECT
    p.EmployeeNumber,
    p.Age,
    j.Department,
    j.JobRole,
    j.JobLevel,
    t.YearsInCompany,
    t.YearsSinceLastPromotion,
    j.PerformanceRating,
    fb.JobInvolvement,
    fb.JobSatisfaction,
    t.Attrition
FROM emp_tenure      t
JOIN emp_personal    p  ON t.EmployeeNumber = p.EmployeeNumber
JOIN emp_job_details j  ON t.EmployeeNumber = j.EmployeeNumber
JOIN emp_feedback    fb ON t.EmployeeNumber = fb.EmployeeNumber
WHERE t.YearsSinceLastPromotion >= 5
ORDER BY t.YearsSinceLastPromotion DESC;


-- ─────────────────────────────────────────────────────────────────
-- VIEW 4 | Distance & Demographics Impact on Attrition
--   Problem : Do long commutes hurt certain demographic groups more?
-- ─────────────────────────────────────────────────────────────────
DROP VIEW IF EXISTS view_distance_attrition;
CREATE VIEW view_distance_attrition AS
SELECT
    p.MaritalStatus,
    CASE
        WHEN p.Age BETWEEN 18 AND 25 THEN '18-25'
        WHEN p.Age BETWEEN 26 AND 35 THEN '26-35'
        WHEN p.Age BETWEEN 36 AND 45 THEN '36-45'
        WHEN p.Age BETWEEN 46 AND 55 THEN '46-55'
        ELSE '56+'
    END                                                                 AS AgeGroup,
    COUNT(*)                                                             AS TotalEmployees,
    SUM(CASE WHEN t.Attrition = 'Yes' THEN 1 ELSE 0 END)              AS AttritionCount,
    ROUND(
        SUM(CASE WHEN t.Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                                                    AS AttritionRate_Pct,
    ROUND(AVG(p.DistanceFromHome), 1)                                   AS AvgDistance
FROM emp_personal p
JOIN emp_tenure   t ON p.EmployeeNumber = t.EmployeeNumber
WHERE p.DistanceFromHome > 15
GROUP BY p.MaritalStatus, AgeGroup
ORDER BY AttritionRate_Pct DESC;


-- ================================================================
-- STEP 7: Stored Procedures  (4 procedures, one per problem)
-- ================================================================

DELIMITER $$

-- ─────────────────────────────────────────────────────────────────
-- SP 1 | Talent retention by department
--   CALL sp_talent_retention(NULL);          -- all departments
--   CALL sp_talent_retention('Sales');       -- filter by dept
-- ─────────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_talent_retention$$
CREATE PROCEDURE sp_talent_retention(IN p_department VARCHAR(50))
BEGIN
    SELECT
        j.Department,
        j.JobRole,
        COUNT(*)                                                          AS TotalEmployees,
        ROUND(AVG(f.MonthlyIncome), 2)                                   AS AvgMonthlyIncome,
        SUM(CASE WHEN t.Attrition = 'Yes' THEN 1 ELSE 0 END)           AS TotalAttrition,
        ROUND(
            SUM(CASE WHEN t.Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0
            / COUNT(*), 2
        )                                                                  AS AttritionRate_Pct
    FROM emp_job_details j
    JOIN emp_financial   f ON j.EmployeeNumber = f.EmployeeNumber
    JOIN emp_tenure      t ON j.EmployeeNumber = t.EmployeeNumber
    WHERE p_department IS NULL OR j.Department = p_department
    GROUP BY j.Department, j.JobRole
    ORDER BY AvgMonthlyIncome DESC;
END$$


-- ─────────────────────────────────────────────────────────────────
-- SP 2 | Overtime burnout report
--   CALL sp_overtime_burnout(NULL);                    -- all roles
--   CALL sp_overtime_burnout('Research Scientist');    -- one role
-- ─────────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_overtime_burnout$$
CREATE PROCEDURE sp_overtime_burnout(IN p_jobrole VARCHAR(50))
BEGIN
    SELECT
        j.JobRole,
        j.OverTime,
        COUNT(*)                                   AS EmployeeCount,
        ROUND(AVG(fb.WorkLifeBalance),         2)  AS AvgWorkLifeBalance,
        ROUND(AVG(fb.JobSatisfaction),         2)  AS AvgJobSatisfaction,
        SUM(CASE WHEN t.Attrition = 'Yes' THEN 1 ELSE 0 END)  AS AttritionCount,
        ROUND(
            SUM(CASE WHEN t.Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0
            / COUNT(*), 2
        )                                           AS AttritionRate_Pct
    FROM emp_job_details j
    JOIN emp_feedback    fb ON j.EmployeeNumber = fb.EmployeeNumber
    JOIN emp_tenure      t  ON j.EmployeeNumber = t.EmployeeNumber
    WHERE p_jobrole IS NULL OR j.JobRole = p_jobrole
    GROUP BY j.JobRole, j.OverTime
    ORDER BY j.JobRole, j.OverTime DESC;
END$$


-- ─────────────────────────────────────────────────────────────────
-- SP 3 | Stagnant employees (configurable threshold)
--   CALL sp_stagnant_employees(5);    -- 5+ years without promotion
--   CALL sp_stagnant_employees(3);    -- lower threshold
-- ─────────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_stagnant_employees$$
CREATE PROCEDURE sp_stagnant_employees(IN p_min_years INT)
BEGIN
    SET p_min_years = IFNULL(p_min_years, 5);
    SELECT
        p.EmployeeNumber,
        p.Age,
        j.Department,
        j.JobRole,
        t.YearsInCompany,
        t.YearsSinceLastPromotion,
        j.PerformanceRating,
        fb.JobInvolvement,
        fb.JobSatisfaction,
        t.Attrition
    FROM emp_tenure      t
    JOIN emp_personal    p  ON t.EmployeeNumber = p.EmployeeNumber
    JOIN emp_job_details j  ON t.EmployeeNumber = j.EmployeeNumber
    JOIN emp_feedback    fb ON t.EmployeeNumber = fb.EmployeeNumber
    WHERE t.YearsSinceLastPromotion >= p_min_years
    ORDER BY t.YearsSinceLastPromotion DESC;
END$$


-- ─────────────────────────────────────────────────────────────────
-- SP 4 | Distance-based attrition risk
--   CALL sp_distance_risk(15);    -- employees > 15 miles away
--   CALL sp_distance_risk(10);    -- lower threshold
-- ─────────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_distance_risk$$
CREATE PROCEDURE sp_distance_risk(IN p_min_distance INT)
BEGIN
    SET p_min_distance = IFNULL(p_min_distance, 15);
    SELECT
        p.MaritalStatus,
        CASE
            WHEN p.Age BETWEEN 18 AND 25 THEN '18-25'
            WHEN p.Age BETWEEN 26 AND 35 THEN '26-35'
            WHEN p.Age BETWEEN 36 AND 45 THEN '36-45'
            WHEN p.Age BETWEEN 46 AND 55 THEN '46-55'
            ELSE '56+'
        END                                                                  AS AgeGroup,
        COUNT(*)                                                              AS TotalEmployees,
        SUM(CASE WHEN t.Attrition = 'Yes' THEN 1 ELSE 0 END)               AS AttritionCount,
        ROUND(
            SUM(CASE WHEN t.Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0
            / COUNT(*), 2
        )                                                                     AS AttritionRate_Pct,
        ROUND(AVG(p.DistanceFromHome), 1)                                    AS AvgDistance
    FROM emp_personal p
    JOIN emp_tenure   t ON p.EmployeeNumber = t.EmployeeNumber
    WHERE p.DistanceFromHome >= p_min_distance
    GROUP BY p.MaritalStatus, AgeGroup
    ORDER BY AttritionRate_Pct DESC;
END$$

DELIMITER ;


-- ================================================================
-- STEP 8: Verification Queries  (run these to confirm everything)
-- ================================================================

-- Row counts per table (each must be ~1470)
SELECT 'emp_personal'    AS table_name, COUNT(*) AS total_rows FROM emp_personal
UNION ALL
SELECT 'emp_job_details',               COUNT(*)               FROM emp_job_details
UNION ALL
SELECT 'emp_financial',                 COUNT(*)               FROM emp_financial
UNION ALL
SELECT 'emp_feedback',                  COUNT(*)               FROM emp_feedback
UNION ALL
SELECT 'emp_tenure',                    COUNT(*)               FROM emp_tenure;

-- Attrition distribution (should be ~84% No, ~16% Yes)
SELECT Attrition, COUNT(*) AS cnt,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM emp_tenure), 1) AS pct
FROM emp_tenure GROUP BY Attrition;

-- VIEW 1: Talent Retention
SELECT '=== VIEW 1: Talent Retention ===' AS info;
SELECT * FROM view_talent_retention;

-- VIEW 2: Overtime Satisfaction
SELECT '=== VIEW 2: Overtime Satisfaction (sample) ===' AS info;
SELECT * FROM view_overtime_satisfaction LIMIT 20;

-- VIEW 3: Promotion Stagnation
SELECT '=== VIEW 3: Promotion Stagnation (sample) ===' AS info;
SELECT * FROM view_promotion_stagnation LIMIT 20;

-- VIEW 4: Distance Attrition
SELECT '=== VIEW 4: Distance Attrition ===' AS info;
SELECT * FROM view_distance_attrition;

-- Test stored procedures
CALL sp_talent_retention(NULL);
CALL sp_overtime_burnout(NULL);
CALL sp_stagnant_employees(5);
CALL sp_distance_risk(15);

-- List all objects created
SELECT TABLE_NAME   AS object_name, 'TABLE' AS type
FROM   information_schema.TABLES
WHERE  TABLE_SCHEMA = 'HR_Analytics' AND TABLE_TYPE = 'BASE TABLE'
UNION ALL
SELECT TABLE_NAME,  'VIEW'
FROM   information_schema.VIEWS
WHERE  TABLE_SCHEMA = 'HR_Analytics'
UNION ALL
SELECT ROUTINE_NAME, ROUTINE_TYPE
FROM   information_schema.ROUTINES
WHERE  ROUTINE_SCHEMA = 'HR_Analytics'
ORDER BY type, object_name;

-- ================================================================
-- ✅ Setup complete!  Database HR_Analytics is ready.
-- Next step: open hr_ai_agent.py in Jupyter Notebook
-- ================================================================

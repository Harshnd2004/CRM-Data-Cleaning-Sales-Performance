SELECT * FROM crm.`accurex_crm_800_rows (1)`;

CREATE TABLE crm_clean AS SELECT * FROM crm.`accurex_crm_800_rows (1)`;

DROP TABLE IF EXISTS crm_clean;
CREATE TABLE crm_clean LIKE crm.`accurex_crm_800_rows (1)`; -- or your original table structure

SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';
LOAD DATA LOCAL INFILE 'C:/Users/2025a.LAPTOP/Downloads/Accurex_CRM_800_Rows (1).csv'
INTO TABLE crm_clean
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM crm_clean;

-- Cleaning name, emails, phone
SET SQL_SAFE_UPDATES = 0;
ALTER TABLE crm_clean MODIFY Phone VARCHAR(20);
UPDATE crm_clean SET Customer_Name = TRIM(Customer_Name);
UPDATE crm_clean SET Email = LOWER(TRIM(Email));
UPDATE crm_clean SET Phone = TRIM(Phone);
UPDATE crm_clean SET Phone = NULL WHERE Phone = '0' OR Phone = '';
UPDATE crm_clean SET Customer_Type = TRIM(Customer_Type);
UPDATE crm_clean SET Phone = REPLACE(REPLACE(REPLACE(Phone,' ',''),'-',''),'+91','');
UPDATE crm_clean SET Email = NULL WHERE Email = '' OR Email = '0';
UPDATE crm_clean SET Phone = NULL WHERE Phone = '0' OR Phone = '';
SET SQL_SAFE_UPDATES = 1;

-- Duplicate Email
SELECT Email, COUNT(*) AS cnt, GROUP_CONCAT(Lead_ID)
FROM crm_clean
GROUP BY Email
HAVING COUNT(*)>1;

-- Duplicate Phone
SELECT Phone, COUNT(*) AS cnt
FROM crm_clean
WHERE Phone != ''
GROUP BY Phone
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS total,
COUNT(Phone) AS phone_filled,
COUNT(*) - COUNT(Phone) AS phone_missing
FROM crm_clean;

-- Missing Data
SELECT 
COUNT(*) AS total,
SUM(CASE WHEN Email = '' THEN 1 ELSE 0 END) AS missing_email,
SUM(CASE WHEN Phone IS NULL OR Phone = '0' OR Phone = '' THEN 1 ELSE 0 END) as missing_phone
FROM crm_clean;

-- Overdue
SELECT Owner, COUNT(*) AS overdue
FROM crm_clean
WHERE Next_Followup < CURDATE() AND Status = 'Open'
GROUP BY Owner;

DELETE c1 FROM crm_clean c1
JOIN crm_clean c2
ON c1.Email = c2.Email AND c1.Lead_ID > c2.Lead_ID
WHERE c1.Email != '';

SELECT COUNT(*) AS clean_total,
SUM(CASE WHEN Stage='Order Won' THEN 1 ELSE 0 END) AS won,
ROUND(SUM(CASE WHEN Stage='Order Won' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS conversion_pct
FROM crm_clean;

-- 1. Total + Duplicates
SELECT COUNT(*) AS total, COUNT(DISTINCT Lead_ID) AS unique_leads FROM crm_clean;

-- 2. Missing data (final)
SELECT COUNT(*) AS total,
SUM(CASE WHEN Email IS NULL THEN 1 ELSE 0 END) AS missing_email,
SUM(CASE WHEN Phone IS NULL THEN 1 ELSE 0 END) AS missing_phone
FROM crm_clean;

-- 3. Duplicate Emails
SELECT Email, COUNT(*) AS c 
FROM crm_clean 
WHERE Email IS NOT NULL 
GROUP BY Email 
HAVING c > 1;

-- 4. Top Cities
SELECT City, COUNT(*) AS leads 
FROM crm_clean 
GROUP BY City 
ORDER BY leads 
DESC LIMIT 5;

-- 5. Revenue by Customer_Type
SELECT Customer_Type, COUNT(*) AS leads, SUM(Order_Value_INR) AS revenue 
FROM crm_clean 
GROUP BY Customer_Type;

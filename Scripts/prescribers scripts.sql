-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT p1.npi, SUM(p2.total_claim_count) AS total_claim
FROM prescriber AS p1
	JOIN prescription AS p2
	ON p1.npi = p2.npi
WHERE p2.total_claim_count IS NOT NULL
GROUP BY p1.npi
ORDER BY total_claim DESC
LIMIT 1;

--ANSWER: 
	1881634483	99707
		
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT 
		p1.nppes_provider_first_name
	, 	p1.nppes_provider_last_org_name
	, 	p1.specialty_description
	, 	SUM(p2.total_claim_count) AS total_claim
FROM prescriber AS p1
	LEFT JOIN prescription AS p2
	ON p1.npi = p2.npi
WHERE total_claim_count IS NOT NULL
GROUP BY p1.nppes_provider_first_name,
	 	p1.nppes_provider_last_org_name,
	 	p1.specialty_description
ORDER BY total_claim DESC
LIMIT 1;

--ANSWER:
	"BRUCE"	"PENDLEY"	"Family Practice"	99707
	
-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT 
		p1.specialty_description
	,	SUM(p2.total_claim_count) AS total_claim
FROM prescriber AS p1
	LEFT JOIN prescription AS p2
	ON p1.npi = p2.npi
WHERE p2.total_claim_count IS NOT NULL
GROUP BY p1.specialty_description
ORDER BY total_claim DESC
LIMIT 1;

--ANSWER
	"Family Practice"	9752347
	
--   b. Which specialty had the most total number of claims for opioids?
SELECT 
		p1.specialty_description
	, 	SUM(p2.total_claim_count) AS total_claim_count
FROM prescriber AS p1
	LEFT JOIN prescription AS p2
	ON p1.npi = p2.npi
		JOIN drug AS d
		ON p2.drug_name = d.drug_name
WHERE d.opioid_drug_flag = 'Y'
GROUP BY p1.specialty_description
ORDER BY total_claim_count DESC
LIMIT 1;

--ANSWER:
	"Nurse Practitioner"	900845
	
--   c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table
SELECT DISTINCT(specialty_description)
FROM prescriber
WHERE specialty_description NOT IN 
	(SELECT DISTINCT(specialty_description)
	 FROM prescriber
	 JOIN prescription
	 USING(npi)
	 WHERE drug_name IS NOT NULL);

--   d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
--OPTION 1 (dibran's)
SELECT
	specialty_description,
	
	SUM(
		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
		ELSE 0
	END
	) as opioid_claims,
	
	SUM(total_claim_count) AS total_claims,
	
	SUM(
		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
		ELSE 0
	END
	) * 100.0 /  SUM(total_claim_count) AS opioid_percentage
	
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
GROUP BY specialty_description
ORDER BY opioid_percentage DESC;

--OPTION 2 (Jennifer)
WITH ClaimsBySpecialty AS (
    SELECT
        prescriber.specialty_description,
        SUM(prescription.total_claim_count) AS total_claims_for_specialty,
        SUM(CASE
                WHEN drug.opioid_drug_flag = 'Y' THEN prescription.total_claim_count
                ELSE 0
            END) AS total_opioid_claims_for_specialty
    FROM prescriber
   INNER JOIN prescription
        ON prescriber.npi = prescription.npi
   INNER JOIN drug
        ON prescription.drug_name = drug.drug_name
    GROUP BY prescriber.specialty_description
)
SELECT
    cbs.specialty_description,
    cbs.total_claims_for_specialty,
    cbs.total_opioid_claims_for_specialty,
      CASE
         WHEN cbs.total_claims_for_specialty > 0 THEN
            ROUND(
                (CAST(cbs.total_opioid_claims_for_specialty AS NUMERIC) * 100.0) / cbs.total_claims_for_specialty,
                2 -- Round to 2 decimal places
            )
         ELSE
            0.0
     END AS percentage_opioid_claims
FROM ClaimsBySpecialty AS cbs
ORDER BY percentage_opioid_claims DESC; cbs.specialty_description

-- 3. 
--   a. Which drug (generic_name) had the highest total drug cost?
SELECT 
		d.generic_name
	,	MAX(p.total_drug_cost) AS drug_cost
FROM drug AS d
	JOIN prescription AS p
	ON d.drug_name = p.drug_name
GROUP BY d.generic_name
ORDER BY MAX(p.total_drug_cost) DESC
LIMIT 1;																																										
--ANSWER:
	"PIRFENIDONE"	2829174.3


--   b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT 
		d.generic_name
	,	ROUND(SUM(p.total_drug_cost)/SUM(p.total_day_supply), 2) AS total_cost_perday
	FROM drug AS d
	JOIN prescription AS p
	ON d.drug_name = p.drug_name
GROUP BY d.generic_name
ORDER BY total_cost_perday DESC
LIMIT 1;

--ANSWER:
	"C1 ESTERASE INHIBITOR"	3495.22
	
-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 
SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither'
		 END AS drug_type
FROM drug

	-- b. Building neitheroff of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT
    CASE
        WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN drug.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither'
    END AS drug_type,  
    SUM(prescription.total_drug_cost)::MONEY AS total_spent -- Postgres specific cast to the money data type
FROM
    drug 
INNER JOIN prescription 
Using(drug_name)
WHERE drug.opioid_drug_flag = 'Y' OR drug.antibiotic_drug_flag = 'Y'
GROUP BY drug_type
ORDER BY total_spent DESC;

--ANSWER: 
	"opioid"	"$105,080,626.37"
"antibiotic"	"$38,435,121.26"
-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(DISTINCT cbsa)
FROM cbsa
WHERE cbsaname LIKE '%TN%';

--ANSWER: 56

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
(SELECT c.cbsaname, SUM(p.population) AS population, 'largest' AS flag
FROM cbsa AS c
	JOIN fips_county AS f
	ON c.fipscounty = f.fipscounty
		JOIN population AS p
		ON c.fipscounty = p.fipscounty
WHERE f.state = 'TN'
GROUP BY c.cbsaname
ORDER BY population DESC LIMIT 1)

UNION 

(SELECT c.cbsaname, SUM(p.population) AS population, 'Sallest'.
FROM cbsa AS c
	JOIN fips_county AS f
	ON c.fipscounty = f.fipscounty
		JOIN population AS p
		ON c.fipscounty = p.fipscounty
WHERE f.state = 'TN'
GROUP BY c.cbsaname
ORDER BY population DESC LIMIT 1;

--ANSWER
	"cbsa"	"population"
	"Nashville-Davidson--Murfreesboro--Franklin, TN"	1830410	--Largest population
	"Morristown, TN"	116352	--Smallest population
		
--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT fips_county, population,county,state
FROM population
INNER JOIN fips_county USING (fipscounty)
WHERE fipscounty IN (SELECT fipscounty FROM population EXCEPT SELECT DISTINCT fipscounty FROM cbsa)
ORDER BY population DESC
LIMIT 1;

--ANSWER:
	"(SEVIER,TN,47155,47)"	95523	"SEVIER"	"TN"

SELECT  county,population
FROM fips_county
LEFT JOIN cbsa
  ON fips_county.fipscounty=cbsa.fipscounty
JOIN population
  ON fips_county.fipscounty=population.fipscounty
 WHERE cbsa.fipscounty IS  NULL
ORDER BY population DESC

SELECT county, population
FROM fips_county
INNER JOIN population
USING(fipscounty)
WHERE fipscounty NOT IN (
	SELECT fipscounty
	FROM cbsa
)
ORDER BY population DESC;
-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT
		drug_name
	,	total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;


--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECt 
		p.drug_name
	,	p.total_claim_count
	,	d.opioid_drug_flag
FROM prescription AS p
	JOIN drug AS d
	ON p.drug_name = d.drug_name
WHERE total_claim_count >= 3000
	
--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT
		p1.drug_name
	,	p1.total_claim_count
	,	d.opioid_drug_flag
	,	CONCAT(p2.nppes_provider_first_name, ' ', p2.nppes_provider_last_org_name) AS full_name
FROM prescription AS p1
	LEFT JOIN drug AS d
	ON p1.drug_name = d.drug_name
		LEFT JOIN prescriber AS p2
		ON p1.npi = p2.npi
WHERE total_claim_count >= 3000;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drugo tables since you don't need the claims numbers yet.
SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
WITH cte_claims AS 
( 
SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
)
--main query
SELECT 
		cc.npi
	,	cc.drug_name
	,	p.total_claim_count
FROM prescription AS p
	RIGHT JOIN cte_claims AS cc
	ON p.npi = cc.npi
	AND p.drug_name = cc.drug_name
    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

WITH cte_claims AS 
( 
SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
)
--main query
SELECT 
		cc.npi
	,	cc.drug_name
	,	COALESCE(p.total_claim_count, 0) -- first identify the column rhat has a null value
FROM prescription AS p
	RIGHT JOIN cte_claims AS cc
	ON p.npi = cc.npi
	AND p.drug_name = cc.drug_name
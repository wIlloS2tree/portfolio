/*
🚗 Road Accident Data Analysis - SQL Verification
=================================================

📋 Project: UK Road Accident Data Analysis (2019-2022)
🎯 Purpose: Cross-validate Tableau dashboard findings with SQL queries
🛠️ Database: MySQL
📊 Data Source: UK Government Road Accident Statistics UK Government Open Data

Analysis Structure:
1. Primary KPIs - Core accident statistics
2. Vehicle Analysis - Casualties by vehicle categories  
3. Temporal & Geographic Patterns - Time and location insights

영국 도로교통사고 데이터 분석 - SQL 검증
목적: Tableau 대시보드 결과를 SQL 쿼리로 교차 검증
*/

-- Database setup
-- 데이터베이스 설정
USE portfolioproject;

-- Quick data overview
-- 데이터 개요 확인
SELECT * FROM road_accident
LIMIT 10;

-- ===========================================================================
-- 📊 PRIMARY KPI ANALYSIS 기본 핵심 성과 지표 분석
-- ===========================================================================

-- Total casualties in 2022 (dry road conditions only)
-- 2022년 총 사상자 수 (건조한 도로 조건만)
-- Purpose: Key metric for dashboard headline figure
-- 목적: 대시보드 주요 수치

SELECT 
    SUM(number_of_casualties) AS CY_2022_Casualties_Dry_Roads,
    COUNT(DISTINCT accident_index) AS total_accidents_dry
FROM road_accident
WHERE YEAR(accident_date) = 2022
    AND road_surface_conditions = 'Dry'
;

-- Total accidents in 2022
-- 2022년 총 사고 건수
-- Note: Using DISTINCT to avoid double-counting accidents with multiple vehicles
-- 참고: 여러 차량이 관련된 사고의 중복 집계를 피하기 위해 DISTINCT 사용

SELECT 
    COUNT(DISTINCT accident_index) AS CY_2022_Total_Accidents
FROM road_accident
WHERE YEAR(accident_date) = 2022;

-- Casualties by severity level (2022)
-- 사고 심각도별 사상자 수 (2022년)

-- Fatal casualties
SELECT 
    SUM(number_of_casualties) AS CY_2022_Fatal_Casualties
FROM road_accident
WHERE accident_severity = 'Fatal'
    AND YEAR(accident_date) = 2022;

-- Serious casualties  
SELECT 
    SUM(number_of_casualties) AS CY_2022_Serious_Casualties
FROM road_accident
WHERE YEAR(accident_date) = 2022
    AND accident_severity = 'Serious';

-- Slight casualties
SELECT 
    SUM(number_of_casualties) AS CY_2022_Slight_Casualties
FROM road_accident
WHERE YEAR(accident_date) = 2022
    AND accident_severity = 'Slight';

-- Percentage breakdown by severity (all years)
-- 심각도별 비율 분석 (전체 연도)
-- Purpose: Understanding the distribution of accident severity
-- 목적: 사고 심각도 분포 파악

-- Slight casualties percentage
SELECT 
    ROUND(
        CAST(SUM(number_of_casualties) AS DECIMAL(10,2)) * 100 / 
        (SELECT CAST(SUM(number_of_casualties) AS DECIMAL(10,2)) FROM road_accident), 
        2
    ) AS Slight_Casualties_Percentage
FROM road_accident
WHERE accident_severity = 'Slight';

-- Serious casualties percentage
SELECT 
    ROUND(
        CAST(SUM(number_of_casualties) AS DECIMAL(10,2)) * 100 / 
        (SELECT CAST(SUM(number_of_casualties) AS DECIMAL(10,2)) FROM road_accident), 
        2
    ) AS Serious_Casualties_Percentage
FROM road_accident
WHERE accident_severity = 'Serious';

-- Fatal casualties percentage
SELECT 
    ROUND(
        CAST(SUM(number_of_casualties) AS DECIMAL(10,2)) * 100 / 
        (SELECT CAST(SUM(number_of_casualties) AS DECIMAL(10,2)) FROM road_accident), 
        2
    ) AS Fatal_Casualties_Percentage
FROM road_accident
WHERE accident_severity = 'Fatal';




-- ===========================================================================
-- 🚙 VEHICLE TYPE ANALYSIS 차량 유형별 분석  
-- ===========================================================================

/*
Vehicle categorization logic 차량 분류 그룹:
- Cars: Car, Taxi/Private hire car
- Bikes: All motorcycles + Pedal cycle  
- Vans: Various goods vehicles
- Bus: Public transport vehicles
- Agricultural: Farm vehicles
- Other: Everything else
*/

SELECT 
    -- Vehicle categorization using CASE statement
    -- CASE 문을 사용한 차량 분류
    CASE
        WHEN vehicle_type IN ('Agricultural vehicle') 
            THEN 'Agricultural'
        WHEN vehicle_type IN ('Car', 'Taxi/Private hire car') 
            THEN 'Cars'
        WHEN vehicle_type IN (
            'Motorcycle 125cc and under',
            'Motorcycle 50cc and under',
            'Motorcycle over 125cc and up to 500cc',
            'Motorcycle over 500cc',
            'Pedal cycle'
        ) THEN 'Bikes'
        WHEN vehicle_type IN (
            'Bus or coach (17 or more pass seats)',
            'Minibus (8 - 16 passenger seats)'
        ) THEN 'Bus'
        WHEN vehicle_type IN (
            'Goods 7.5 tonnes mgw and over',
            'Goods over 3.5t and under 7.5t',
            'Van / Goods 3.5 tonnes mgw or under'
        ) THEN 'Van'
        ELSE 'Other'
    END AS vehicle_group,
    SUM(number_of_casualties) AS total_casualties,
    -- Calculate percentage of total casualties
    -- 전체 사상자 중 비율 계산
    ROUND(
        SUM(number_of_casualties) * 100.0 / 
        (SELECT SUM(number_of_casualties) FROM road_accident), 
        2
    ) AS casualty_percentage
FROM road_accident
GROUP BY
    CASE
        WHEN vehicle_type IN ('Agricultural vehicle') THEN 'Agricultural'
        WHEN vehicle_type IN ('Car', 'Taxi/Private hire car') THEN 'Cars'
        WHEN vehicle_type IN (
            'Motorcycle 125cc and under',
            'Motorcycle 50cc and under',
            'Motorcycle over 125cc and up to 500cc',
            'Motorcycle over 500cc',
            'Pedal cycle'
        ) THEN 'Bikes'
        WHEN vehicle_type IN (
            'Bus or coach (17 or more pass seats)',
            'Minibus (8 - 16 passenger seats)'
        ) THEN 'Bus'
        WHEN vehicle_type IN (
            'Goods 7.5 tonnes mgw and over',
            'Goods over 3.5t and under 7.5t',
            'Van / Goods 3.5 tonnes mgw or under'
        ) THEN 'Van'
        ELSE 'Other'
    END
ORDER BY total_casualties DESC;



-- ===========================================================================
-- 📅 TEMPORAL ANALYSIS 시간별 분석
-- ===========================================================================

-- Monthly casualty trends for 2022
-- 2022년 월별 사상자 추세
-- Purpose: Identify seasonal patterns in road accidents
-- 목적: 도로교통사고의 계절적 패턴 식별


SELECT 
    MONTHNAME(accident_date) AS month_name,
    SUM(number_of_casualties) AS monthly_casualties,
    COUNT(DISTINCT accident_index) AS monthly_accidents,
    -- Average casualties per accident
    -- 사고당 평균 사상자 수
    ROUND(
        SUM(number_of_casualties) / COUNT(DISTINCT accident_index), 
        2
    ) AS avg_casualties_per_accident
FROM road_accident
WHERE YEAR(accident_date) = 2022
GROUP BY MONTH(accident_date), MONTHNAME(accident_date)
ORDER BY MONTH(accident_date);



-- ===========================================================================
-- 🛣️ ROAD TYPE & GEOGRAPHIC ANALYSIS 도로 유형 및 지리적 분석  
-- ===========================================================================

-- Casualties by road type (2022)
-- 도로 유형별 사상자 수 (2022년)

SELECT 
    road_type,
    SUM(number_of_casualties) AS casualties_2022,
    COUNT(DISTINCT accident_index) AS accidents_2022,
    -- Calculate percentage distribution
    -- 비율 분포 계산
    ROUND(
        SUM(number_of_casualties) * 100.0 / 
        (SELECT SUM(number_of_casualties) FROM road_accident WHERE YEAR(accident_date) = 2022),
        2
    ) AS percentage_of_total
FROM road_accident
WHERE YEAR(accident_date) = 2022
GROUP BY road_type
ORDER BY casualties_2022 DESC;

-- Urban vs Rural accident analysis (2022)
-- 도시 vs 농촌 사고 분석
-- Purpose: Compare accident severity between urban and rural areas
-- 목적: 도시와 농촌 지역 간 사고 심각도 비교

SELECT 
    urban_or_rural_area,
    SUM(number_of_casualties) AS total_casualties_2022,
    COUNT(DISTINCT accident_index) AS total_accidents_2022,
    -- Percentage of total casualties
    -- 전체 사상자 중 비율
    ROUND(
        SUM(number_of_casualties) * 100.0 / 
        (SELECT SUM(number_of_casualties) FROM road_accident WHERE YEAR(accident_date) = 2022),
        2
    ) AS percentage_of_total,
    -- Average casualties per accident by area type
    -- 지역 유형별 사고당 평균 사상자 수
    ROUND(
        SUM(number_of_casualties) / COUNT(DISTINCT accident_index), 
        2
    ) AS avg_casualties_per_accident
FROM road_accident
WHERE YEAR(accident_date) = 2022
GROUP BY urban_or_rural_area
ORDER BY total_casualties_2022 DESC;



-- ===========================================================================
-- 📍 TOP RISK LOCATIONS 위험 지역 상위 순위
-- ===========================================================================

-- Top 10 local authorities by total casualties (all years)
-- 총 사상자 수 기준 상위 10개 지역 (전체 연도)
-- Purpose: Identify high-risk geographic areas for targeted interventions
-- 목적: 집중 개입이 필요한 고위험 지리적 지역 식별

SELECT 
    local_authority,
    SUM(number_of_casualties) AS total_casualties,
    COUNT(DISTINCT accident_index) AS total_accidents,
    -- Calculate average casualties per accident for each area
    -- 각 지역별 사고당 평균 사상자 수 계산
    ROUND(
        SUM(number_of_casualties) / COUNT(DISTINCT accident_index), 
        2
    ) AS avg_casualties_per_accident,
    -- Show what percentage this area represents of total casualties
    -- 이 지역이 전체 사상자 중 차지하는 비율
    ROUND(
        SUM(number_of_casualties) * 100.0 / 
        (SELECT SUM(number_of_casualties) FROM road_accident),
        2
    ) AS percentage_of_total_casualties
FROM road_accident
GROUP BY local_authority
ORDER BY total_casualties DESC
LIMIT 10;


-- ===========================================================================
-- 🔍 ADDITIONAL INSIGHTS 추가 인사이트
-- ===========================================================================

-- Weather impact analysis
-- 날씨 영향 분석

SELECT 
    weather_conditions,
    SUM(number_of_casualties) AS total_casualties,
    COUNT(DISTINCT accident_index) AS total_accidents,
    ROUND(
        SUM(number_of_casualties) / COUNT(DISTINCT accident_index), 
        2
    ) AS avg_casualties_per_accident
FROM road_accident
GROUP BY weather_conditions
ORDER BY total_casualties DESC;

-- Road surface conditions impact
-- 도로 표면 조건 영향

SELECT 
    road_surface_conditions,
    SUM(number_of_casualties) AS total_casualties,
    COUNT(DISTINCT accident_index) AS total_accidents,
    ROUND(
        SUM(number_of_casualties) * 100.0 / 
        (SELECT SUM(number_of_casualties) FROM road_accident),
        2
    ) AS percentage_of_total
FROM road_accident
GROUP BY road_surface_conditions
ORDER BY total_casualties DESC;


/*
=============================================================================
📋 SUMMARY FOR TABLEAU CROSS-VALIDATION 교차 검증용 요약

Use these SQL results to verify:
이 SQL 결과를 사용하여 다음을 검증:

1. ✅ Primary KPI numbers match Tableau dashboard
2. ✅ Vehicle type distribution aligns with visualizations  
3. ✅ Monthly trends show same patterns
4. ✅ Geographic analysis confirms hotspot locations
5. ✅ Weather/road condition impacts are consistent

Key Validation Points 주요 검증 포인트:
- Total 2022 casualties should match across platforms
- Vehicle category percentages should be identical
- Monthly casualty counts should align exactly
- Top 10 locations should be in same order

=============================================================================
*/

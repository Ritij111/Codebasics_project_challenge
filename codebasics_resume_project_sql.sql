/* 1. Provide the list of markets in which customer "Atliq Exclusive"
	  operates its business in the APAC region. */
      
SELECT DISTINCT market
FROM dim_customer
WHERE 
	customer = "Atliq Exclusive"
    AND region = "APAC" ;
    
    
/* 2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */    


WITH CTE AS 
(SELECT  
	MAX((SELECT COUNT(DISTINCT product_code )
	FROM fact_sales_monthly
    GROUP BY fiscal_year
	HAVING fiscal_year = 2020 )) AS Uni_pro_20,

	MAX((SELECT COUNT(DISTINCT product_code)
	FROM fact_sales_monthly
    GROUP BY fiscal_year
	HAVING fiscal_year = 2021 )) AS Uni_pro_21
    
    FROM fact_sales_monthly)
    SELECT *,ROUND((Uni_pro_21-Uni_pro_20)*100/Uni_pro_20,2) AS pct_inc
    FROM CTE ;
    
    
    /*
3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count
*/

SELECT segment,COUNT(DISTINCT product_code) AS cnt
FROM dim_product
GROUP BY segment
ORDER BY cnt DESC ;


/*
4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference
*/


WITH
CTE_1 AS 
	(SELECT p.segment, COUNT(DISTINCT s.product_code) AS product_count_2020
	FROM fact_sales_monthly s
	JOIN dim_product p
	USING (product_code)
	WHERE fiscal_year = 2020
	GROUP BY segment),

CTE_2 AS
	(SELECT p.segment, COUNT(DISTINCT s.product_code) AS product_count_2021
	FROM fact_sales_monthly s
	JOIN dim_product p
	USING (product_code)
	WHERE fiscal_year = 2021
	GROUP BY segment)
    
SELECT segment, product_count_2020, product_count_2021, 
		(product_count_2021-product_count_2020) AS diff, 
		ROUND((product_count_2021-product_count_2020)*100/product_count_2020,2) AS pct_inc
FROM CTE_1 c1
JOIN CTE_2 c2
USING (segment)
;



/*
5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost
*/

WITH CTE AS 
	(SELECT * 
	FROM fact_manufacturing_cost 
	WHERE manufacturing_cost IN (
			(SELECT  MIN(manufacturing_cost) FROM fact_manufacturing_cost), 
			(SELECT  MAX(manufacturing_cost) FROM fact_manufacturing_cost) ))

SELECT c.product_code, p.product, c.manufacturing_cost
FROM CTE c
JOIN dim_product p
USING (product_code) ;


/*
6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage
*/



WITH CTE AS 
 (SELECT *,ROUND(AVG(pre_invoice_discount_pct),4) AS avg_discount_pct
FROM fact_pre_invoice_deductions
WHERE fiscal_year =2021 
GROUP BY customer_code
)

SELECT ct.customer_code, dc.customer, ct.avg_discount_pct
FROM CTE ct
JOIN dim_customer dc
USING (customer_code)
WHERE dc.market="India"
ORDER BY avg_discount_pct DESC
LIMIT 5
 ;
 
 
/*
7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount
*/


SELECT monthname(s.date) AS `month`, s.fiscal_year, ROUND(SUM((s.sold_quantity*gross_price)),2) AS Gross_sales_Amount
FROM fact_sales_monthly s
JOIN fact_gross_price g
USING (product_code,fiscal_year)
WHERE 
	customer_code  IN (SELECT customer_code FROM dim_customer
					 WHERE customer = "Atliq Exclusive")
GROUP BY s.fiscal_year, `month`
;


/*
8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity
*/

SELECT 
	get_fiscal_quater(date) AS `Quarter`,
	SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY `Quarter`
ORDER BY  total_sold_quantity DESC
LIMIT 1;


/*
9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage
*/

WITH CTE AS 
(SELECT c.channel, ROUND(SUM((s.sold_quantity*g.gross_price)/1000000),2) AS gross_sales_mln
FROM fact_sales_monthly s
JOIN fact_gross_price g
ON 
	s.product_code = g.product_code
    ANd s.fiscal_year = g.fiscal_year

JOIN dim_customer c
ON s.customer_code = c.customer_code 
WHERE s.fiscal_year = 2021
GROUP BY c.channel ) 

SELECT *, 
	ROUND(gross_sales_mln*100/SUM(gross_sales_mln) OVER(),2) AS percentage
FROM
CTE ;



/*
10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order
*/

WITH CTE AS 
	(SELECT p.division, s.product_code, p.product,SUM(s.sold_quantity) AS total_sold_quantity,
    DENSE_RANK() OVER(PARTITION BY division ORDER BY SUM(s.sold_quantity) DESC) AS rank_order
	FROM fact_sales_monthly s
	JOIN dim_product p 
	USING (product_code)
	WHERE s.fiscal_year = 2021
	GROUP BY s.product_code )
    
SELECT *
FROM CTE
WHERE rank_order <=3 ;



        
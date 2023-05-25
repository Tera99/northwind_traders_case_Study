use northwind_traders;

/*
=============
PRODUCTS
=============
What are the top selling products and categories?
What are the flop products and categories?
What do sales look like over time?
Are there any monthly trends in sales?
*/

CREATE TEMPORARY TABLE product_summary
SELECT 
	od.orderID,
    od.productID,
    orderDate,
	productName,
    categoryName,
    quantity,
	ROUND((od.unitPrice-od.unitPrice*od.discount) * od.quantity, 2) AS salesRevenue
FROM order_details od
	LEFT JOIN products p
    ON od.productID = p.productID
    LEFT JOIN categories c
    ON p.categoryID = c.categoryID
    LEFT JOIN orders o
    ON od.orderID = o.orderID
;

-- SELECT * FROM product_summary;

-- What are the 10 top products by revenue?
SELECT 
	productName,
    ROUND(SUM(salesRevenue), 2) AS revenue,
    SUM(quantity) AS volume
FROM product_summary
GROUP BY
	productName
ORDER BY
	revenue DESC	
LIMIT 10
;

-- What are the 10 flop products by revenue?
SELECT 
	productName,
    ROUND(SUM(salesRevenue), 2) AS revenue,
    SUM(quantity) AS volume
FROM product_summary
GROUP BY
	productName
ORDER BY
	revenue
LIMIT 10
;

-- Rank the categories by revenue
SELECT 
	categoryName,
    ROUND(SUM(salesRevenue), 2) AS revenue,
    SUM(quantity) AS volume
FROM product_summary
GROUP BY
	categoryName
ORDER BY
	revenue DESC
;

-- revenue and volume over time (weekly)
SELECT * FROM product_summary;

-- most recent order date
SELECT MAX(orderDate)
FROM product_summary;

SELECT 
	YEAR(orderDate) AS yr,
    MONTH(orderDate) AS mo,
    WEEK(orderDate) AS wk,
    MIN((DATE(orderDate))) AS week_start_date,
    ROUND(SUM(salesRevenue), 2) AS weekly_revenue,
    SUM(quantity) as weekly_volume
FROM product_summary
GROUP BY
	YEAR(orderDate),
    MONTH(orderDate),
    WEEK(orderDate)
;

-- revenue and volume over time (monthly)
SELECT 
	YEAR(orderDate) AS yr,
    MONTH(orderDate) AS mo,
    MIN((DATE(orderDate))) AS start_date,
    ROUND(SUM(salesRevenue), 2) AS monthly_revenue,
    SUM(quantity) as monthly_volume
FROM product_summary
GROUP BY
	YEAR(orderDate),
    MONTH(orderDate)
;

-- revenue and volume over time (year)
SELECT 
	YEAR(orderDate) AS yr,
    ROUND(SUM(salesRevenue), 2) AS annual_revenue,
    SUM(quantity) as annual_volume
FROM product_summary
GROUP BY
	YEAR(orderDate)
;
-- Sales increased 3x from 2013 to 2014
-- 2015 is only half way done in this data set
-- if trends for 2015 continue, sales will increase 1.4x over 2014

-- seasonal trends - months
SELECT 
    MONTH(orderDate) AS mo,
    ROUND(SUM(salesRevenue), 2) AS revenue,
    SUM(quantity) as volume
FROM product_summary
GROUP BY
    MONTH(orderDate)
ORDER BY
	revenue DESC
;
-- top selling months are Jan, March, April
-- bottom selling months are Aug, May, June

-- all time total sales 
SELECT 
	SUM(salesRevenue),
    SUM(quantity)
FROM product_summary;

-- !!!!
-- Summary table for product and category sales
-- export as .csv to tableau
SELECT * FROM product_summary;

/*
Products
Analysis
Northwind has 77 products in 8 categories. It has made a total of 
$1.26 million in sales and sold over 51K units. 

The top products are Cote de Blaye, Thuringer Rostbratwurst, and Raclette Courdavault.
The bottom (flop) products are Chocolade, Geitost, and Genen Shouyu. The top selling 
categories are beverages, dairy products, and confections. 

Sales increased 3x from 2013 to 2014. 2015 is only half way done in this data set
If trends for 2015 continue, sales will increase 1.4x over 2014.

The top selling months are January, March, and April. 
The bottomselling months are August, May, and June.

Recommendations
Since warmer months have slower sales in general, one possible way to boost sales 
would be to add more products from the popular categories, beverages and 
confections, that would be appealing in the warmer weather. 

Offering discounts to our most loyal customers during May and June could also
help boost sales. 
*/


/*
==================
Customers
==================
Who are our most valuable customers?
What countries contribute the most to our sales?
Are there any high value but inactive customers we could reach out to?
*/
-- orderVolume and sales by orderID
CREATE TEMPORARY TABLE revenue_and_itemcount
SELECT 
	orderID,
	ROUND(SUM((unitPrice-unitPrice*discount) * quantity), 2) AS salesRevenue,
    COUNT(*) AS itemCount
FROM order_details
GROUP BY
	orderID
;
SELECT * FROM revenue_and_itemcount;


CREATE TEMPORARY TABLE orders_and_customers
SELECT 
	o.orderID,
    o.customerID,
    o.orderDate,
    ri.salesRevenue,
    ri.itemCount,
    c.companyName,
    c.city,
    c.country
FROM orders o
	LEFT JOIN revenue_and_itemcount ri
    ON o.orderID = ri.orderID
    LEFT JOIN customers c
    ON o.customerID = c.customerID
;

-- SELECT * FROM orders_and_customers;

-- number of customers
SELECT COUNT(DISTINCT customerID) FROM customers;
-- 91 customers

-- number of countries
SELECT COUNT(DISTINCT country) FROM customers;
-- 21 countries

-- average revenue per customer
SELECT AVG(salesRevenue)
FROM orders_and_customers;
-- 1525.05 USD

-- customers ranked by revenue
SELECT 
    companyName,
    ROUND(SUM(salesRevenue), 2) AS revenue,
    SUM(itemCount) AS volume,
    MAX(orderDate) AS lastOrder
FROM orders_and_customers
GROUP BY 
	companyName 
ORDER BY
	revenue DESC
;
-- top 3 customers: QUICK-Stop, Ernst Handel, Save-a-lot Markets
-- each have more than $100K in lifetime revenue

-- countries ranked by sales
SELECT 
    country,
    ROUND(SUM(salesRevenue), 2) AS revenue,
    SUM(itemCount) AS volume
FROM orders_and_customers
GROUP BY 
	country 
ORDER BY
	revenue DESC
;
-- Top 3 countries: USA, Germany, Austria

-- inactive high value customers
-- sales higher than average 1525
SELECT 
	customerID,
    companyName,
    ROUND(SUM(salesRevenue), 2) AS revenue,
    SUM(itemCount) AS volume,
    MAX(orderDate) AS lastOrder
FROM orders_and_customers
GROUP BY 
	customerID, companyName 
HAVING 
	revenue > 1525 AND
	lastOrder < '2015-02-06' -- arbitrary, last order at least 3 months or older per data set
ORDER BY
	revenue DESC
;

-- !!!!!!
-- summary table
-- export as CSV for Tableau
SELECT * FROM orders_and_customers;
-- !!!!!

/*
There are 91 customers in 21 countries. Average sales revenue per customer is $1525 USD

Northwinds top customers be sales revenue are: QUICK-Stop, Ernst Handel, Save-a-lot Markets 
Each have more than $100K in lifetime revenue. 
Top countries for revenue are USA, Germany, Austria.

There are 11 customers with more than average total sales who have not placed an order in the 
last 3 months (relative to the data set which ends in 2015-05-06) The top inactive high values 
customers are: Mere Paillarde, Blondesddsl pere et fils, and Seven Seas Imports

*/

/*
==================
Employees
==================
Who are the top performing managers and employees?
*/

-- order volume and sales revenue by employee & manager
-- employee, manager, orderVolume, salesRevenue

-- employee & manager
CREATE TEMPORARY TABLE employee_manager
SELECT
	e.employeeID,
	e.employeeName,
    e2.employeeName AS manager
FROM 
	employees e
    JOIN employees e2
    ON e.reportsTo = e2.employeeID
WHERE 
	e.title = 'Sales Representative'
;



CREATE TEMPORARY TABLE revenue_items_by_employee
SELECT 
	employeeID,
    SUM(salesRevenue) AS sales,
    SUM(itemCount) AS itemsOrdered
FROM orders o
	LEFT JOIN revenue_and_itemcount ri
    ON o.orderID = ri.orderID
GROUP BY
	employeeID
;

-- revenue and volume by employee and manager
DROP TEMPORARY TABLE revenue_and_volume_by_emplyee_manager;
CREATE TEMPORARY TABLE revenue_and_volume_by_emplyee_manager 
SELECT 
	em.employeeName,
    em.manager,
    ROUND(ri.sales, 2) AS salesRevenue,
    ri.itemsOrdered AS salesVolume
FROM employee_manager em
	LEFT JOIN revenue_items_by_employee ri
    ON em.employeeID = ri.employeeID
;

-- Top performing employees by revenue
SELECT * 
FROM revenue_and_volume_by_emplyee_manager
ORDER BY 
	salesRevenue DESC;

-- Top performing managers by revenue
SELECT 
	manager,
    SUM(salesRevenue) AS total_sales,
    SUM(salesVolume) AS volume
FROM revenue_and_volume_by_emplyee_manager
GROUP BY 
	manager
ORDER BY 
	total_sales DESC
;

-- !!!!
-- Summary Table
-- export as csv to Tableau
SELECT * 
FROM revenue_and_volume_by_emplyee_manager
;
/*
Employees
Analysis
There are 9 total employees. 6 sales representatives, 
2 sales managers, and 1 vice president of sales. 

Top performing employees are Margaret Peacock, Janet Leverling, 
and Nancy Davolio who all work for Laura Callahan.
Bottom performing employees all work for Steven Buchanan.

Recommendations
Consider performance bonuses for top performing manager and employees. 
Reach out to Steven Buchanan to find out if his team needs 
additional training or resources to bring up sales numbers. 
*/
    
/*
==============
SHIPPING COSTS
==============
What are freight costs by shipper?
Are there any opportunities to save on shipping costs?
*/

SELECT * FROM orders;
SELECT * FROM shippers;

SELECT 
	s.companyName,
    o.shipperID,
    ROUND(SUM(freight),2) AS total_cost,
    COUNT(DISTINCT o.orderID) AS order_volume,
    ROUND(SUM(freight) / COUNT(DISTINCT o.orderID),2) AS shipping_cost_per_order,
    ROUND(AVG(DATEDIFF(o.requiredDate, o.orderDate))) AS avg_days_to_deliver
FROM orders o
	LEFT JOIN shippers s
    ON o.shipperID = s.shipperID
GROUP BY
	o.shipperID, s.companyName
;

/*
Shipping
Analysis
Speedy Express is substantially less expensive than the other shipping companies, but makes up
less than 1/3rd of our shipping. However, shipping costs could be due to types of shipping so 
the average days to delivery is included to evaluate the shipping speed of different carriers. 
All shippers are shown to have the same shipping speed. 

Recommendations
Consider increasing use of Speedy Express to reduce shipping costs.
Alternatively, negotiate lower rates with the other two shippers. 

*/





/*
1. Top Selling Products
Top 10 products by total sales value.Also included product name, total quantity sold and total sales value.
*/

SELECT 
  p.product_id, 
  -- p.product_category, 
  SUM(oi.total_price) as total_sales, 
  count(oi.product_id) as total_orders
from orders as o
INNER JOIN
orderItems as oi
ON oi.order_id = o.order_id
INNER JOIN
products as p
on p.product_id = oi.product_id

GROUP BY 1
ORDER BY 3 DESC
LIMIT 10

/*
2. Revenue by Category
Calculated total revenue generated by each product category.
*/

SELECT 
    p.product_category,
	SUM(oi.total_price),
	round(SUM(oi.total_price)/(SELECT SUM(total_price) FROM orderItems)*100) as contribution
FROM products as p
INNER JOIN 
orderItems AS oi
ON p.product_id = oi.product_id
GROUP BY p.product_category
ORDER BY 2 DESC

/*
3. Average Order Value 
Computed the average order value for each customers and diplayed only customers with more than 5 orders.
*/


SELECT o.customer_id AS customer_id,
       SUM(oi.total_price)/(COUNT(oi.order_id)) AS average_order_by_customer,
	   COUNT(oi.order_id) as count_of_orders
FROM orderItems as oi
INNER JOIN
orders as o
on o.order_id = oi.order_id
GROUP BY customer_id 
HAVING COUNT(oi.order_id) > 5

/*
4. Monthly Sales Trend
Monthly total sales over the past year with sales trend, grouping by month, returned current_month sale and last month sale!
*/
 
SELECT month,
       year,
	   total_sale as current_month_sale,
	   LAG( total_sale,1) over(order by month) as last_month_sale 
from 
(
SELECT EXTRACT('MONTH' from o.order_purchase_timestamp) as month,
       EXTRACT('Year' from o.order_purchase_timestamp) as year,
       ROUND(SUM(oi.total_price)) as total_sale
FROM orders as o
INNER JOIN orderItems as oi
on o.order_id = oi.order_id
where EXTRACT('Year' from o.order_purchase_timestamp) = 2018
GROUP BY 1,2
order by month
)

/*
5. Customers with No Purchases
Customers who have registered but never placed an order.
*/

Select * from customers where customer_id not in 
(Select distinct(customer_id) from orders)

/*
6. Best-Selling Categories by State
Best-selling product category for each state with total sales.
*/

Select * from 
(
SELECT 
 SUM(oi.total_price) as total_sales,
 oi.product_id,
 c.customer_city,
 RANK() OVER (
   PARTITION BY c.customer_city  
   ORDER BY sum(oi.total_price) ASC) as rank
FROM customers AS c
INNER JOIN
orders AS o
ON c.customer_id = o.customer_id
INNER JOIN
orderItems as oi
ON oi.order_id = o.order_id 
GROUP BY 2,3 
) 
WHERE RANK = 1
ORDER BY total_sales desc

/*
7. Customer Lifetime value
Total value of orders placed by each customer over their lifetime and ranked customers based on their CLTV
*/

SELECT c.customer_id,
       sum(oi.total_price) as CLTV,
	   DENSE_RANK () OVER ( order by sum(oi.total_price) desc) as rank
FROM customers AS c
INNER JOIN
orders AS o
ON c.customer_id = o.customer_id
INNER JOIN
orderItems as oi
ON oi.order_id = o.order_id
group by 1


/*
8.Delivery Date Alerts
Products that took more than 7 days to get delivered
*/

SELECT order_id,
 o.order_delivered_customer_date - o.order_purchase_timestamp AS differ
FROM orders AS o 
WHERE
o.order_delivered_customer_date - o.order_purchase_timestamp > '7'

/*
9.Most returned products
*/

SELECT oi.product_id, COUNT(*),((SELECT COUNT(*) from orders WHERE order_status = 'cancelled')*100/(SELECT COUNT(*) from orders as o
INNER JOIN orderItems as oi
on o.order_id = oi.order_id
WHERE o.order_status = 'canceled'))

from orders as o
INNER JOIN orderItems as oi
on o.order_id = oi.order_id
WHERE o.order_status = 'canceled'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10

/*
10. Percentage of delivered orders
*/

SELECT ((SELECT count(*) from orders  where order_status = 'delivered')*100/(SELECT COUNT(*) FROM orders))


/*
11.Inactive sellers - Sellers with no sales after 2017
*/

SELECT * from sellers WHERE seller_id NOT IN ( 
SELECT seller_id
from orders as o
INNER JOIN orderItems as oi
on o.order_id = oi.order_id
WHERE o.order_purchase_timestamp >= CURRENT_DATE - interval '84 month' )


/*
12.Identified customers that cancel most of the items.
*/

SELECT COUNT(o.order_id) as total_orders,
       COUNT(o.order_status) as total_cancelled_orders, 
       o.customer_id
from orders as o
WHERE o.order_status = 'canceled'
GROUP by 3
ORDER by 1 desc

-- none of the customers have cancelled more than once

/*
13.Top 5 cutomers by orders in each state
*/


SELECT * from
(
SELECT o.customer_id,COUNT(o.order_id),c.customer_state,SUM(oi.total_price),
       RANK() OVER (PARTITION BY c.customer_state ORDER BY COUNT(o.order_id) DESC )
from 
orderItems as oi
INNER JOIN orders as o
on oi.order_id = o.order_id
INNER JOIN customers as c
on o.customer_id = c.customer_id 
GROUP BY 1,3
) as t1
WHERE RANK <=5


/*
14.Stored procedure
Product quantity is reduced from the inventory as soon as a product is sold. 
Sales records are updated based on the product and the quantity purchased.
*/

SELECT * from orders

CREATE or REPLACE PROCEDURE add_sales
(
p_order_id VARCHAR,
p_customer_id VARCHAR,
p_order_item_id VARCHAR,
p_product_id VARCHAR,
p_seller_id VARCHAR,
p_price FLOAT,
p_freight_value FLOAT,
p_product_category VARCHAR,
p_product_quantity INT
)
LANGUAGE plpgsql
AS $$

DECLARE

v_count INT;

BEGIN

-- checking stock and product availibility in inventory
SELECT 
      COUNT(*)
	  INTO 
	  v_count
	FROM products
    WHERE product_id = p_product_id
	AND
	product_quantity >= p_product_quantity;

  IF v_count > 0 THEN
  -- add into orders and orders_items table
  -- update product quantity in products

     -- adding into orders table
     INSERT INTO orders(order_id,customer_id,order_item_id)
	 VALUES (p_order_id,p_customer_id);

     -- adding into orderItems table
	 INSERT INTO orderItems(order_id,order_item_id,product_id,seller_id,price,freight_value)
	 VALUES (p_order_id,p_order_item_id,p_product_id,p_seller_id,p_price,p_freight_value);

     -- updating inventory
	 UPDATE products
	 SET product_quantity = product_quantity - p_product_quantity
	 WHERE product_id = p_product_id;

	 RAISE NOTICE 'Thank you for the order, inventory updated.';

  ELSE
      RAISE NOTICE 'Thank you for your info, the product is out of stock';

  END IF;	  


END;
$$



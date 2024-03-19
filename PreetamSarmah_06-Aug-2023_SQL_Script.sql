/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/
# Here since customer id is primary key , we can use count() on that column 
# There are a total of 994 customers, across all states
SELECT 
	state, 
    COUNT(customer_id) AS customer_count
FROM customer_t
GROUP BY state
ORDER BY customer_count DESC ;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. */
WITH cust_rating AS (
	SELECT
		quarter_number,
		customer_feedback,
		CASE
			WHEN customer_feedback = 'Very Bad' THEN 1
			WHEN customer_feedback = 'Bad' THEN 2
			WHEN customer_feedback = 'Okay' THEN 3
			WHEN customer_feedback = 'Good' THEN 4
			WHEN customer_feedback = 'Very Good' THEN 5
		END AS rating
FROM order_t
)

SELECT 
	cust_rating.quarter_number,
    ROUND(AVG(cust_rating.rating),2) AS average_rating
FROM  cust_rating
GROUP BY cust_rating.quarter_number
ORDER BY cust_rating.quarter_number;

# average rating shows a drop from Q1 to Q4



-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback. */
 WITH cust_feedback AS (
	SELECT
		quarter_number,
		customer_feedback,
		COUNT(customer_feedback) feedback_count_per_type
	FROM order_t 
GROUP BY quarter_number,customer_feedback
ORDER BY quarter_number) 

SELECT
	* ,
	SUM(cust_feedback.feedback_count_per_type) OVER ( PARTITION BY cust_feedback.quarter_number ORDER BY  cust_feedback.quarter_number) AS feedback_count_per_quarter,
	cust_feedback.feedback_count_per_type * 100/SUM(cust_feedback.feedback_count_per_type) OVER ( PARTITION BY cust_feedback.quarter_number ORDER BY cust_feedback.quarter_number) AS percentage_feedback
FROM cust_feedback
GROUP BY cust_feedback.quarter_number,cust_feedback.customer_feedback;

# positive feedback such as good and very good are going down from quarter 1 to quarter 4
# Where as negative feedback such as bad and very feed is going up from quarter 1 to quarter 4 , which indicates that the customers are getting dissatisfied over time
-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

SELECT 
	p.vehicle_maker,
	COUNT(o.customer_id) AS customer_count
FROM 
	product_t AS p 
	INNER JOIN order_t AS o 
	ON p.product_id = o.product_id
GROUP BY p.vehicle_maker
ORDER BY COUNT(o.customer_id) DESC
LIMIT 5;

# Chevloret,Ford,Toyota,Pontiac,Dodge are top 5 vehicle makers

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/
SELECT 
    a.rnk,
	a.customer_count, 
    a.state,
    GROUP_CONCAT( a.vehicle_maker  SEPARATOR ', ' ) AS vehicle_maker_list
FROM (
	SELECT 
	COUNT(c.customer_id) AS customer_count,
	p.vehicle_maker,
	c.state,
	RANK() OVER (PARTITION BY c.state  ORDER BY COUNT(c.customer_id) DESC) AS rnk
FROM
	order_t o 
	INNER JOIN  product_t AS p 
	ON p.product_id = o.product_id
	INNER JOIN  customer_t AS c
	ON c.customer_id = o.customer_id
GROUP BY p.vehicle_maker,c.state) AS a
WHERE a.rnk =1
GROUP BY a.state;
# Using group_concat as there are multiple vehicle makers for rank 1 over state based on count of customers (descending)
-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/
SELECT 
	quarter_number,
    COUNT(order_id) AS order_count
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/ 
#[ (Present Quarter – Past Quarter) /Past Quarter ] * 100 = QoQ growth percentage
# Revenue is calculated based on price after discount of the vehicle * quantity per order
With revenue_t AS (      
	SELECT 
		quarter_number,
		ROUND(SUM((1-discount)*vehicle_price*quantity),2) AS revenue
	FROM order_t 
	GROUP BY quarter_number
	ORDER BY quarter_number
)

SELECT 
	*,
   ROUND((revenue_t.revenue - (LAG(revenue_t.revenue) OVER (ORDER BY quarter_number)))*100/ (LAG(revenue_t.revenue) OVER ( ORDER BY revenue_t.quarter_number)),2) AS qoq_percentage
FROM revenue_t;
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/
# Revenue is calculated based on price after discount of the vehicle * quantity per order
SELECT 
	quarter_number,
	ROUND(SUM((1-discount)*vehicle_price*quantity),2) AS revenue,
	COUNT(order_id) AS order_count
FROM order_t 
GROUP BY quarter_number
ORDER BY revenue DESC;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/
SELECT
	UPPER(c.credit_card_type) AS credit_card_type,
    ROUND(AVG(o.discount) *100,2) AS average_discount_percentage
FROM 
	order_t o
INNER JOIN 
	customer_t c
	ON o.customer_id = c.customer_id
GROUP BY c.credit_card_type
ORDER BY average_discount_percentage DESC;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/
# datediff returns the value in number of days
SELECT 
	quarter_number,
	ROUND(AVG(datediff(ship_date,order_date))) AS avg_ship_time_in_days
FROM order_t
GROUP BY quarter_number
ORDER BY avg_ship_time_in_days;



-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------


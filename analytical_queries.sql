-- Суммарная выручка (с учётом скидки) по месяцам 
-- за последний год от последней даты заказа

SELECT 
	DATE_TRUNC('month', order_date)::date AS month,
	SUM(quantity * unit_price * (1 - discount))
FROM orders
JOIN order_details USING(order_id)
WHERE order_date >= (SELECT MAX(order_date) FROM orders) - INTERVAL '1 year'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

-- Пронумеруй клиентов по убыванию общей выручки, оставь только первые 5
SELECT
	customer_id,
	SUM(quantity * unit_price * (1 - discount)) AS revenue
FROM order_details
JOIN orders USING(order_id)
GROUP BY customer_id
ORDER BY revenue DESC
LIMIT 5;

-- Для каждого клиента посчитай кумулятивную сумму 
-- его заказов по дате (нарастающий итог)
WITH order_prices AS(
	SELECT
		SUM(quantity * unit_price * (1 - discount)) AS order_price,
		order_id,
		customer_id,
		order_date
	FROM order_details
	JOIN orders USING(order_id)
	GROUP BY customer_id, order_id, order_date
	ORDER BY customer_id, order_date
)

SELECT 
	order_date,
	customer_id,
	SUM(order_price) OVER(PARTITION BY customer_id ORDER BY order_date) AS cumulative_revenue
FROM order_prices


-- Сравни выручку каждого месяца с предыдущим: абсолютное изменение и процент прироста
-- LAG(monthly_revenue) OVER(ORDER BY month)
WITH monthly_revenues AS(
	SELECT 
		DATE_TRUNC('month', order_date)::date AS month,
		SUM(quantity * unit_price * (1 - discount)) AS revenue
	FROM orders
	JOIN order_details USING(order_id)
	GROUP BY month
	ORDER BY month
)

SELECT 
	revenue,
	LAG(revenue) OVER(ORDER BY month) AS last_month_revenue,
	revenue - LAG(revenue) OVER(ORDER BY month) AS difference,
	(100 * (revenue - LAG(revenue) OVER(ORDER BY month)) / LAG(revenue) OVER(ORDER BY month)) AS grow_percent,
	month
FROM monthly_revenues;

-- Найди клиентов, у которых нет ни одного заказа 
-- за последние 90 дней (относительно максимальной даты)
SELECT 
	customer_id
FROM customers
EXCEPT
SELECT customer_id
FROM orders
WHERE order_date >= (
		SELECT MAX(order_date) - INTERVAL '90 days'
		FROM orders);

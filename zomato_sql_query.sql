
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;


--- Data Analysis Question?


select * from sales;
select * from product;
select * from users;
select * from goldusers_signup;

select * from sales 
inner join product
on sales.product_id = product.product_id;

-- 1. What is the total amount each customer spent on zomato?

SELECT
    sales.userid,
    SUM(product.price) AS total_amount_spent
FROM
    sales
INNER JOIN
    product ON sales.product_id = product.product_id
GROUP BY
    sales.userid;



--2.  How many days has each customer visited zomato?

SELECT * FROM sales;

SELECT userid, COUNT(DISTINCT created_date) AS customer_visited from sales
GROUP BY userid;

-- 3. What was the first product purchased by each customer;

SELECT 
    *
FROM 
    (
        SELECT 
            *,
            RANK() OVER (PARTITION BY userid ORDER BY created_date) AS rnk
        FROM 
            sales
    ) temp_table
WHERE 
    rnk = 1;


-- Alternate method

SELECT 
    sales.userid, 
    product.product_name, 
    sales.created_date 
FROM 
    sales
INNER JOIN 
    product ON product.product_id = sales.product_id
WHERE 
    sales.created_date IN (
        SELECT 
            MIN(created_date) 
        FROM 
            sales 
        GROUP BY 
            userid
    );




-- 4. What is the most purchased item on the menu and how many times was it purchased by all customer?
SELECT
    userid,
    COUNT(product_id) AS product_purchased
FROM
    sales
WHERE
    product_id = (
        SELECT TOP 1
            product_id
        FROM
            sales
        GROUP BY
            product_id
        ORDER BY
            COUNT(product_id) DESC
    )
GROUP BY
    userid;



-- 5. Which item was the most popular for each customer?

SELECT 
    *
FROM 
    (
        SELECT 
            *,
            RANK() OVER (PARTITION BY userid ORDER BY product_count DESC) AS rnk
        FROM 
            (
                SELECT 
                    userid, 
                    product_id, 
                    COUNT(product_id) AS product_count 
                FROM 
                    sales 
                GROUP BY 
                    userid, 
                    product_id
            ) a
    ) b
WHERE 
    rnk = 1;

-- 6. Which item was purchased first by the customer after they become they member?
       
	    select * from (
        SELECT s.userid, created_date, product_id, gold_signup_date, 
		rank() over(partition by s.userid order by created_date) as rnk 
               
        FROM 
            sales s 
        INNER JOIN 
            goldusers_signup g ON s.userid = g.userid
        WHERE 
            created_date >= gold_signup_date) a
			where rnk = 1;

select * from users;

-- 7. which item purchased just before the customer became the member?

SELECT 
    *
FROM 
    (
        SELECT 
            c.*, 
            RANK() OVER (PARTITION BY c.userid ORDER BY c.created_date DESC) AS rnk
        FROM 
            (
                SELECT 
                    sales.userid, 
                    sales.created_date, 
                    sales.product_id, 
                    goldusers_signup.gold_signup_date 
                FROM 
                    sales
                INNER JOIN 
                    goldusers_signup ON sales.userid = goldusers_signup.userid AND created_date <= gold_signup_date
            ) c
    ) d
WHERE 
    rnk = 1;


--- 8. What is the total orders and amount spent for each member before they became a member?

select 
  sales.userid, 
  count(created_date) as total_orders, 
  sum(price) as amount_spent 
from 
  sales 
  inner join goldusers_signup on sales.userid = goldusers_signup.userid 
  and created_date <= gold_signup_date 
  inner join product on sales.product_id = product.product_id 
group by 
  sales.userid;


--- 9.if buying each product generates points for eg 5rs = 2 zomato points and 
--- each product has different purchasing points  for eg. for p1 rs5=1 zomato points
--- for p2 10rs= 5 zomato points and p3 2rs = 1 zomato point
-- calculated points collected by each customers and for each product most points have been given till now.


select c.userid, sum(c.points_earned) * 2.5 as money_earned from
(select b.*, b.amount/points as points_earned from
(select a.*, case 
when a.product_id = 1 then 5 
when a.product_id = 2 then 2
when a.product_id = 3 then 5
end as points 
from
(select s.userid, p.product_id, sum(p.price) as amount  from sales s
inner join product p
on s.product_id = p.product_id 
group by s.userid, p.product_id) a ) b)c
group by userid;
 
select * from
(select d.*, rank() over(order by d.points desc) as rnk from
(select c.product_id, sum(c.points_earned) as points from
(select b.*, b.amount/points as points_earned from
(select a.*, case 
when a.product_id = 1 then 5 
when a.product_id = 2 then 2
when a.product_id = 3 then 5
end as points 
from
(select s.userid, p.product_id, sum(p.price) as amount  from sales s
inner join product p
on s.product_id = p.product_id 
group by s.userid, p.product_id) a ) b)c
group by c.product_id)d)e
where rnk = 1;


--- 10. In the first one year after a customer join the gold program (including their join date) 
--- irrespective of what the customer purchased they earn 5 zomato points for every 10 rs spent
--- who earn more 1 or 3 and what was their earnings in their first year?

select 
  *, 
  rank() over(
    order by 
      earn_points desc
  ) rnk 
from 
  (
    select 
      *, 
      a.price / a.points as earn_points 
    from 
      (
        select 
          s.userid, 
          p.price, 
          2 as points 
        from 
          sales s 
          inner join goldusers_signup g on s.userid = g.userid 
          and created_date >= gold_signup_date 
          and created_date <= DATEADD(year, 1, gold_signup_date) 
          inner join product p on p.product_id = s.product_id
      ) a
  ) b;



-- 11. rank all the transactions of the customer?

select *, rank() over(partition by userid order by created_date desc) rnk from sales;

-- 12. Rank all the transactions for each member whenever they are a zomato gold member 
-- for every non gold member transaction  mark as na



select 
  d.userid, 
  d.created_date, 
  d.gold_signup_date, 
  case when rnk = 0 then 'na' else rnk end as rnk 
from 
  (
    select 
      c.*, 
      cast(
        case when gold_signup_date is null then 0 else rank() over(
          partition by userid 
          order by 
            created_date desc
        ) end as varchar
      ) as rnk 
    from 
      (
        select 
          s.userid, 
          s.created_date, 
          g.gold_signup_date 
        from 
          sales s 
          left join goldusers_signup g on s.userid = g.userid 
          and created_date >= gold_signup_date
      ) c
  ) d;



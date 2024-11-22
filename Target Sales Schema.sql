-- Target Project - Advanced SQL

-- Customers Table
CREATE TABLE customers 
(
customer_id VARCHAR(40) PRIMARY KEY,
customer_unique_id VARCHAR(40),
customer_zip_code_prefix INT,
customer_city VARCHAR (40),
customer_state CHAR(2)
);

-- GeoLocation Table
CREATE TABLE geolocation
(
geolocation_zip_code_prefix SMALLINT PRIMARY KEY,
geolocation_lat DECIMAL,
geolocation_lng DECIMAL,
geolocation_city VARCHAR(40),
geolocation_state CHAR(2)
);

-- Order Items Table
CREATE TABLE orderItems
(
order_id VARCHAR(40) PRIMARY KEY,
order_item_id SMALLINT,
product_id VARCHAR(40),
seller_id VARCHAR(40),
shipping_limit_date TIMESTAMP,
price DECIMAL,
freight_value DECIMAL
);

ALTER TABLE orderItems DROP CONSTRAINT orderItems_pkey;
ALTER TABLE orderItems add PRIMARY KEY ("order_item_id");


--- Orders Table
CREATE TABLE orders
(
order_id VARCHAR(40) PRIMARY KEY,
customer_id VARCHAR(40),
order_status VARCHAR(20),
order_purchase_timestamp TIMESTAMP,
order_approved_at TIMESTAMP,
order_delivered_carrier_date TIMESTAMP,
order_delivered_customer_date TIMESTAMP,
order_estimated_delivery_date TIMESTAMP
);

--- PAYMENTS TABLE

CREATE TABLE payments 
(
order_id VARCHAR(40),
payment_sequential SMALLINT,
payment_type VARCHAR(20),
payment_installments SMALLINT,
payment_value DECIMAL
)

--- PRODUCTS TABLE

CREATE TABLE products 
(
product_id VARCHAR(40),
product_category VARCHAR(50),
product_name_length SMALLINT,
product_description_length SMALLINT,
product_photos_qty SMALLINT,
product_weight_g INTEGER,
product_length_cm SMALLINT,
product_height_cm SMALLINT,
product_width_cm SMALLINT
)

--- SELLERS TABLE

CREATE TABLE sellers
(
seller_id VARCHAR(40),
seller_zip_code_prefix SMALLINT,
seller_city VARCHAR(50),
seller_state CHAR(2)
)

ALTER TABLE payments add PRIMARY KEY ("order_id");
ALTER TABLE orders add FOREIGN KEY ("customer_id")

ALTER TABLE payments DROP CONSTRAINT payments_pkey;
ALTER TABLE payments ADD CONSTRAINT fk_payments FOREIGN KEY (orders) REFERENCES order_id; 

DROP TABLE orders;
DROP TABLE payments;

-- NEW ORDERS TABLE

CREATE TABLE orders
(
order_id VARCHAR(40) PRIMARY KEY,
customer_id VARCHAR(40),
order_status VARCHAR(20),
order_purchase_timestamp TIMESTAMP,
order_approved_at TIMESTAMP,
order_delivered_carrier_date TIMESTAMP,
order_delivered_customer_date TIMESTAMP,
order_estimated_delivery_date TIMESTAMP,
CONSTRAINT fk_customer FOREIGN KEY (customer_id)
REFERENCES customers(customer_id)
);


-- NEW PAYMENTS TABLE

CREATE TABLE payments 
(
order_id VARCHAR(40),
payment_sequential SMALLINT,
payment_type VARCHAR(20),
payment_installments SMALLINT,
payment_value DECIMAL,
CONSTRAINT fk_order FOREIGN KEY (order_id)
REFERENCES orders(order_id)
)

--Adding Foreign keys to orderItems Table

ALTER TABLE orderItems ADD CONSTRAINT fk_orderId FOREIGN KEY (order_id) 
          REFERENCES orders (order_id);

ALTER TABLE products ADD PRIMARY KEY (product_id);
		  
ALTER TABLE orderItems ADD CONSTRAINT fk_productId FOREIGN KEY (product_id) 
          REFERENCES products (product_id);

ALTER TABLE sellers ADD PRIMARY KEY (seller_id);
		  
ALTER TABLE orderItems ADD CONSTRAINT fk_sellerId FOREIGN KEY (seller_id) 
          REFERENCES sellers (seller_id);		

--- Making changes to geolocation to import data

ALTER TABLE geolocation drop CONSTRAINT geolocation_pkey;

ALTER TABLE geolocation ALTER COLUMN geolocation_zip_code_prefix TYPE INT; 	

ALTER TABLE sellers ALTER COLUMN seller_zip_code_prefix TYPE INT; 


ALTER TABLE orderItems 
ADD COLUMN total_price FLOAT;


UPDATE orderItems
SET total_price = price + freight_value;


--- updating price + shipping charges

-- End of Schema.
















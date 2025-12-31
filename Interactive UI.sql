SELECT * FROM products
SELECT * FROM reorders
SELECT * FROM shipments
SELECT * FROM stock_entries
SELECT * FROM suppliers


-- 1. Total Suppliers

SELECT count(*) as total_suppliers FROM suppliers;

-- 2. Total products

SELECT count(*) as total_products FROM products;

-- 3. Total categories dealing

SELECT COUNT(DISTINCT category) as total_categories FROM products;

-- 4. Total sales value made in last 8 months (quantity*price)

SELECT ROUND(SUM(abs(se.change_quantity)*p.price),2) total_sales_values_in_last_8_motnhs
FROM
	stock_entries as se
	JOIN products as p 
	ON se.product_id = p.product_id
	WHERE change_type= 'Sale' 
    AND 
    se.entry_date >= (SELECT DATE_SUB(max(entry_date), interval 8 month) FROM stock_entries)

-- 5. Total restock value made in last 8 months (quantity*price)    

SELECT ROUND(SUM(abs(se.change_quantity)*p.price),2) as total_restock_values_in_last_8_motnhs
FROM
	stock_entries as se
	JOIN products as p 
	ON se.product_id = p.product_id
	WHERE change_type= 'Restock' 
    AND 
    se.entry_date >= (SELECT DATE_SUB(max(entry_date), interval 8 month) FROM stock_entries)
    

-- 6. Number of orders which have less than reorder_level of stock quantity and reorder statud is pending

SELECT COUNT(*) FROM products as p WHERE p.stock_quantity < p.reorder_level
AND product_id NOT IN (SELECT DISTINCT product_id from reorders WHERE status= 'Pending')

-- 7. Suppliers and ther contact details
 SELECT supplier_name, contact_name, email, phone from suppliers
 
 -- 8. Product with there suppliers and current stock
 
SELECT p.product_name, s.supplier_name, p.stock_quantity, p.reorder_level from products as p
JOIN suppliers s
ON p.supplier_id= s.supplier_id
ORDER BY p.product_name

-- 9. Product needing reorder

SELECT product_id,product_name, stock_quantity, reorder_level FROM products
WHERE stock_quantity< reorder_level

-- 10. Add a new product to the database

DELIMITER $$
CREATE PROCEDURE AddNewProductManualID(
	in p_name varchar(255),
    in p_category varchar(100),
    in p_price decimal(10,2),
    in p_stock int,
    in p_reorder int,
    in p_supplier int
) 
BEGIN
		DECLARE new_prod_id int ;
		DECLARE new_shipment_id int ;
		DECLARE new_entry_id int ;
-- # make changes in product table
-- # generate the product id

	SELECT MAX(product_id)+1 INTO new_prod_id FROM products ; 

	INSERT INTO products(product_id, product_name, category, price, stock_quantity, reorder_level, supplier_id)
	values(new_prod_id, p_name, p_category, p_price, p_stock, p_reorder, p_supplier);

-- # make changes in shipment table
-- # generate the shipment id 

	SELECT MAX(shipment_id)+1 INTO new_shipment_id FROM shipments ;
    
	INSERT INTO shipments(shipment_id, product_id, supplier_id, quantity_received, shipment_date)
	values(new_shipment_id,new_prod_id, p_supplier,p_stock, CURDATE());

-- # make changes in stock_entries table
-- # generate the entry id 

	SELECT MAX(entry_id)+1 INTO new_entry_id FROM stock_entries ;

	INSERT INTO stock_entries(entry_id,product_id,change_quantity,change_type, entry_date )
	values(new_entry_id,new_prod_id, p_stock, 'RESTOCK', CURDATE());
end $$
DELIMITER ;

call AddNewProductManualID('Smart Watch', 'Elctronics', 999.99, 100, 25, 5)

SELECT * FROM products WHERE product_name= 'Smart Watch'
SELECT * FROM shipments WHERE product_id= 201
SELECT * from stock_entries where product_id= 201

-- 11. Product History(finding shipment, sales, purchase)

CREATE OR REPLACE VIEW product_inventory_history AS
SELECT pih.product_id, 
pih.record_type,
pih.record_date,
pih.quantity,
pih.change_type,
pr.supplier_id
 FROM (
	select product_id, 
	'Shipment' AS record_type,
	shipment_date AS record_date, 
	quantity_received  AS quantity,
	null AS change_type
	FROM shipments
	UNION ALL
	SELECT product_id,
	'Stock Entry' AS record_type,
	entry_date AS record_date,
	change_quantity AS quantity,
	change_type
	FROM stock_entries
) pih
JOIN products pr on pih.product_id= pr.product_id
 
-- example to check
SELECT * FROM product_inventory_history
WHERE product_id=123
ORDER BY record_date

-- 12. Place an order

INSERT INTO reorders (reorder_id, product_id, reorder_quantity, reorder_date, status)
SELECT 
MAX(reorder_id)+1,
101,
200,
curdate(),
'Ordered'
FROM reorders

SELECT * FROM reorders  ORDER BY reorder_id DESC

SELECT * FROM products WHERE product_id=2

-- 13. Recieve reorder

DELIMITER $$
CREATE procedure MarkReorderAsRecieved(in in_reorder_id int)
BEGIN
DECLARE prod_id int;
DECLARE qty int;
DECLARE sup_id int;
DECLARE new_shipment_id int;
DECLARE new_entry_id int;

START Transaction;

-- # get product_id, quantity from reorder

SELECT product_id, reorder_quantity
INTO prod_id, qty
FROM reorders
WHERE reorder_id= in_reorder_id ;

-- # get supplier_id from products

SELECT supplier_id
INTO sup_id
FROM products
WHERE product_id= prod_id;

-- # update reorder table

UPDATE reorders
SET status= 'Received'
WHERE reorder_id= in_reorder_id;

-- # Update quantity in product table

UPDATE products
SET stock_quantity= stock_quantity+qty
WHERE product_id= prod_id;
 
-- # insert record into shipment table

SELECT MAX(shipment_id)+1 into new_shipment_id FROM shipments;
INSERT INTO shipments(shipment_id, product_id, supplier_id, quantity_received, shipment_date)
VALUES (new_shipment_id, prod_id, sup_id, qty, CURDATE());

-- # insert record into restock

 SELECT MAX(entry_id)+1 into new_entry_id FROM stock_entries;
 INSERT INTO stock_entries( entry_id, product_id, change_quantity, change_type, entry_date)
 VALUES (new_entry_id, prod_id, qty, 'Restock', CURDATE());
 
 COMMIT;
 END $$
 DELIMITER ;
 
 CALL MarkReorderAsRecieved(2)


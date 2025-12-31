import pymysql


def connect_to_db():
    return pymysql.connect(
        host="127.0.0.1",
        user="root",
        password="Karishma1996",
        database="project_data",
        port=3306
    )

db= connect_to_db()

def get_basic_info(cursor):
    queries = {
        'Total Supplier': 'SELECT count(*) as total_suppliers FROM suppliers',

        'Total Products': 'SELECT count(*) as total_products FROM products',

        'Total Categories dealing': 'SELECT COUNT(DISTINCT category) as total_categories FROM products',

        'Total sales values(Last 8 months)': '''SELECT ROUND(SUM(abs(se.change_quantity)*p.price),2) total_sales_values_in_last_8_motnhs 
                                          FROM
                                        	stock_entries as se
                                            JOIN products as p 
                                        	ON se.product_id = p.product_id
                                        	WHERE change_type= 'Sale' 
                                            AND 
                                            se.entry_date >= (SELECT DATE_SUB(max(entry_date), interval 8 month) FROM stock_entries)''',

        'Total restock values(Last 8 months)': '''SELECT ROUND(SUM(abs(se.change_quantity)*p.price),2) as total_restock_values_in_last_8_motnhs
                                            FROM
                                            	stock_entries as se
                                            	JOIN products as p 
                                            	ON se.product_id = p.product_id
                                            	WHERE change_type= 'Restock' 
                                                AND 
                                                se.entry_date >= (SELECT DATE_SUB(max(entry_date), interval 8 month) FROM stock_entries)''',

        'Below reorder and No pending orders': '''SELECT COUNT(*) FROM products as p WHERE p.stock_quantity < p.reorder_level
                                                AND product_id NOT IN (SELECT DISTINCT product_id from reorders WHERE status= 'Pending')''',

    }
    result = {}
    for label, query in queries.items():
        cursor.execute(query)
        row = cursor.fetchone()
        result[label] = list(row.values())[0]
    return result


def get_additional_tables(cursor):
    queries = {
        "Suppliers Contact Details": "SELECT supplier_name, contact_name, email, phone FROM suppliers",

        "Products with Supplier and Stock": """
            SELECT 
                p.product_name,
                s.supplier_name,
                p.stock_quantity,
                p.reorder_level
            FROM products p
            JOIN suppliers s ON p.supplier_id = s.supplier_id
            ORDER BY p.product_name ASC
        """,

        "Products Needing Reorder": """
            SELECT product_name, stock_quantity, reorder_level
            FROM products
            WHERE stock_quantity <= reorder_level
        """
    }
    tables={}
    for label, query in queries.items():
        cursor.execute(query)
        tables[label]= cursor.fetchall()

    return tables


def get_categories(cursor):
    cursor.execute('SELECT DISTINCT category FROM products ORDER BY category ASC')
    rows= cursor.fetchall()
    return [row['category'] for row in rows]

def get_supplier(cursor):
    cursor.execute('SELECT supplier_id, supplier_name FROM suppliers ORDER BY supplier_name ASC')
    return cursor.fetchall()

def add_new_manual_id(cursor, db, p_name, p_category, p_price, p_stock, p_reorder, p_supplier):
    proc_call = "call AddNewProductManualID( %s, %s, %s, %s, %s, %s)"
    params = (p_name, p_category, p_price, p_stock, p_reorder, p_supplier)
    cursor.execute(proc_call, params)
    db.commit()

def get_all_products(cursor):
    cursor.execute('SELECT product_id, product_name FROM products ORDER BY product_name ')
    return cursor.fetchall()

def get_product_history(cursor, product_id):
    query= 'SELECT * FROM product_inventory_history WHERE product_id = %s ORDER BY record_date DESC'
    cursor.execute(query,(product_id,))
    return cursor.fetchall()

def place_reorder(cursor, db, product_id, reorder_quantity):
    query = '''INSERT INTO reorders (reorder_id, product_id, reorder_quantity, reorder_date, status)
                SELECT MAX(reorder_id)+1,
                %s,
                %s,
                CURDATE(),
                'Ordered'
                FROM reorders'''
    cursor.execute(query, (product_id, reorder_quantity))
    db.commit()

def get_pending_reorders(cursor):
    cursor.execute('''SELECT r.reorder_id, p.product_name FROM reorders AS r
                        JOIN products AS p
                        ON r.product_id= p.product_id''')
    return cursor.fetchall()

def mark_reorder_as_received(cursor,db, reorder_id):
    cursor.callproc('MarkReorderAsRecieved', [reorder_id])
    db.commit()
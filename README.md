# Inventory-Management--Interactive-SQL-UI

## Project Overview

This project is about building a powerful web-based application using Python (Streamlit) that allows users to interact with a MySQL database without needing to write any SQL code.

## Objective

In the real world, many people such as managers or team leads need to work with data stored in databases, but they do not know SQL. This application helps those users perform important tasks easily, such as:

Viewing data

Running operations (for example, updating stock)

Checking reports or summaries


## Data Overview

#### What Makes This Project Advanced?

Combines SQL (backend) with Python (frontend)

Uses real database tools like views, stored procedures, and functions

Demonstrates how systems are built for inventory, sales, and operations

Helps understand how real-world applications are designed using multiple layers

Teaches how to build tools that non-technical users can easily use

## Tools & Technologies

- Pandas, NumPy, Matplotlib, Seaborn
- MySQL
- Data Format	CSV file

## Steps followed:

#### Step 1: Build the MySQL Database

We designed a smart and well-structured database that includes:

Tables: Used to store data related to products, orders, shipments, and inventory

Views: Used for generating reports and summaries (for example, product history)

Stored Procedures: For actions like receiving an order and updating stock

Functions: For business calculations (for example, checking if a product needs restocking)

This step simulates how businesses store and organize data with rules built directly into the database.

##### Step 2: Build the Streamlit Frontend

Next, we will create a web interface using Streamlit that allows users to:

View and filter data from tables and views

Use buttons to run stored procedures (for example, “Mark order as received”)

Add or update records (such as new products or prices) using simple clicks

Run calculations using database functions

See live results on the screen without writing any SQL








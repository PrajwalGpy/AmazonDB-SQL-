/* ==========================================================
 E-Commerce Analytics SQL Project
 Description: Contains 20 analytical query requirements
 ========================================================== */
/*-------------------------------------------------
 1. Top selling products  
 Find the top 10 selling products based on total sale, including:
 - Product name
 - Total quantity sold
 - Total sale value
 -------------------------------------------------*/
/*-------------------------------------------------
 2. Revenue by category  
 Find each category and its total revenue including:
 - Percentage contribution of total revenue
 -------------------------------------------------*/
/*-------------------------------------------------
 3. Average order value  
 Compute the average order value, but include only customers who have more than 5 orders.
 -------------------------------------------------*/
/*-------------------------------------------------
 4. Monthly sales trend  
 Query monthly total sales over the past year.
 Return:
 - Monthly grouped sales
 - Current month's sales
 - Last month's sales
 -------------------------------------------------*/
/*-------------------------------------------------
 5. Customers with no purchases  
 Find customers who registered but never made a purchase.
 Include:
 - Customer details
 - Time since registration (if data available)
 -------------------------------------------------*/
/*-------------------------------------------------
 6. Best selling categories by state  
 Find the highest-selling category in each state including:
 - Total sales per category per state
 -------------------------------------------------*/
/*-------------------------------------------------
 7. Customer Lifetime Value (CLV)  
 Calculate the total order value over a customer’s lifetime and rank them by CLV.
 -------------------------------------------------*/
/*-------------------------------------------------
 8. Inventory stock alert  
 Find products where:
 - Stock <10 units
 Include:
 - Warehouse ID
 - Last restock date
 -------------------------------------------------*/
/*-------------------------------------------------
 9. Shipping delay check  
 Identify orders where shipping date > 7 days after order date.
 Include:
 - Customer details
 - Order details
 - Delivery provider
 (Note: later implementation used 3 days)
 -------------------------------------------------*/
/*-------------------------------------------------
 10. Payment success rate  
 Calculate:
 - % of successful payments  
 - Breakdown: failed, successful, refunded
 -------------------------------------------------*/
/*-------------------------------------------------
 11. Top performing sellers  
 Find top 5 sellers based on total sales value.  
 Also include:
 - Successful vs failed orders
 - % successful orders
 -------------------------------------------------*/
/*-------------------------------------------------
 12. Product margin  
 Calculate:
 - Profit margin for each product (Price − Cost)
 Rank from highest to lowest margin.
 -------------------------------------------------*/
/*-------------------------------------------------
 13. Most returned product  
 Find the product with the highest return rate:
 Return rate = (returned units ÷ total sold units) × 100%
 -------------------------------------------------*/
/*-------------------------------------------------
 14. Orders pending shipment  
 Find orders where:
 - Payment completed
 - Not yet shipped
 -------------------------------------------------*/
/*-------------------------------------------------
 15. Inactive sellers  
 Find sellers with no sales in last 6 months.
 Include:
 - Last sale date
 - Past total sales
 -------------------------------------------------*/
/*-------------------------------------------------
 16. Customer type classification  
 Categorize customers:
 - Returning: > 5 returns
 - New: otherwise  
 Return:
 - Customer ID, name, total orders, total returns
 -------------------------------------------------*/
/*-------------------------------------------------
 17. Cross-selling opportunity  
 Identify product pairs where customers who buy one product also commonly buy another
 (E.g., headphones buyers also buying phones).
 -------------------------------------------------*/
/*-------------------------------------------------
 18. Top 5 customers per state  
 Find top 5 customers (per state) based on:
 - Order count
 - Total spend
 -------------------------------------------------*/
/*-------------------------------------------------
 19. Revenue by shipping providers  
 Calculate for each shipping provider:
 - Total revenue handled
 - Number of orders
 - Average delivery time
 -------------------------------------------------*/
/*-------------------------------------------------
 20. Top 10 decreasing revenue products  
 Compare revenue between 2022 and 2023.
 Find top 10 products with the biggest decline.
 -------------------------------------------------*/
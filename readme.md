# 🎬 Movie Streaming & Ticket Booking System (MySQL)

A **complete DBMS project** featuring full **ER design**, **normalization**, **constraints**, **indexes**, **triggers**, **views**, **stored routines**, **CTEs**, **window functions**, and **realistic analytics queries** — all implemented in **MySQL 8.x**.

---

## 🧰 Tech Stack & Requirements

| Component | Requirement |
|------------|--------------|
| **Database** | MySQL 8.x *(required for CTEs & window functions)* |
| **Client** | Any SQL client (CLI / Workbench / DBeaver) |
| **OS** | Windows / macOS / Linux |

---

## 🚀 How to Run

1. **Create the database and all objects**

   ```sql
   SOURCE movie_streaming.sql;
Explore and verify the schema

sql
Copy code
USE ms_booking;
SHOW TABLES;
Run sample analytics queries

sql
Copy code
SOURCE queries.sql;
🧩 Entities (High-Level Overview)
Category	Entities
Users & Access	User, Role
Content	Movie, Genre, MovieGenre
People	Person, MovieCast (actors, directors, crew)
Theatres & Locations	City, Theatre, Screen, Seat
Show Management	Show, ShowSeat (per-show seat inventory)
Transactions	Booking, Ticket, Payment
Engagement	Review

🧮 Normalization
Fully normalized to Third Normal Form (3NF).

Bridge tables handle many-to-many relationships:

MovieGenre

MovieCast

Surrogate Primary Keys (BIGINT) used throughout.

Natural keys / unique constraints where applicable (e.g., user email, screen name per theatre).

Cascading rules ensure data integrity:

Deleting a Show cascades to ShowSeat and Ticket.

Booking deletion restricted unless status is CANCELLED.

📜 Business Rules
✅ Seat booking constraint: A seat can be booked only once per show.

💰 Booking total formula:
Total = SUM(ticket_price) + taxes – discounts

⚠️ Payment handling:
If payment fails, the booking remains PENDING and seats automatically time out after a set window (demonstrated via trigger).

🧾 Review policy:
Only users who have attended a show may leave a review (enforced via foreign keys + app logic).

🧱 What’s Implemented
Feature	Description
DDL	Tables with full PRIMARY KEY, FOREIGN KEY, and CHECK constraints (emulated via triggers)
Indexes	Performance-based indexes on search, filtering, and join-heavy columns
Triggers	Seat availability enforcement and audit logging
Views	Reporting views for movie performance, theatre KPIs, and user insights
Stored Procedures & Functions	Transactional booking workflow and reusable operations
Advanced SQL	Includes CTEs, window functions, and pivot-style aggregates
Sample Data	Seed data for cities, theatres, movies, shows, and users for demo queries

📊 Sample Analytics Queries
Example reports available in queries.sql:

🎟️ Top 5 Movies by Total Tickets Sold

💸 Revenue by Theatre / City

⭐ Average Rating per Movie

⏰ Upcoming Shows by Theatre

👥 Active Subscribers by Plan

🧾 Sample Data
The seed script provides a small, realistic dataset:

Multiple cities and theatres

A few movies and shows

Registered users with active subscriptions and reviews
→ Ensures every query and report returns meaningful, non-empty results.

🧠 Learning Outcomes
By exploring this project, you’ll understand how to:

Design and normalize a real-world relational schema.

Implement PK/FK relationships and constraints effectively.

Use triggers to enforce business rules dynamically.

Write reusable views, functions, and stored procedures.

Query complex data using CTEs and window functions.
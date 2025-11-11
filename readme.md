

# 🎬 Movie Streaming & Ticket Booking System (MySQL)

A **complete DBMS project** featuring **ER design**, **normalization**, **constraints**, **indexes**, **triggers**, **views**, **stored routines**, **CTEs**, **window functions**, and **realistic analytics queries** — all implemented in **MySQL 8.x**.

---

## 🧰 Tech Stack & Requirements

| Component | Requirement |
|------------|--------------|
| **Database** | MySQL 8.x *(required for CTEs & window functions)* |
| **Client** | Any SQL client (CLI / MySQL Workbench / DBeaver) |
| **OS** | Windows / macOS / Linux |

---

## 🚀 How to Run

### 1️⃣ Create the database and all objects
```sql
SOURCE movie_streaming.sql;
````

### 2️⃣ Explore and verify the schema

```sql
USE ms_booking;
SHOW TABLES;
```

### 3️⃣ Run sample analytics queries

```sql
SOURCE queries.sql;
```

---

## 🧩 Entities (High-Level Overview)

| Category                 | Entities                                          |
| ------------------------ | ------------------------------------------------- |
| **Users & Access**       | `User`, `Role`                                    |
| **Content**              | `Movie`, `Genre`, `MovieGenre`                    |
| **People**               | `Person`, `MovieCast` *(actors, directors, crew)* |
| **Theatres & Locations** | `City`, `Theatre`, `Screen`, `Seat`               |
| **Show Management**      | `Show`, `ShowSeat` *(per-show seat inventory)*    |
| **Transactions**         | `Booking`, `Ticket`, `Payment`                    |
| **Engagement**           | `Review`                                          |

---

## 🧮 Normalization

### 🔹 Normal Form

* The schema is fully normalized to **Third Normal Form (3NF)**.

### 🔹 Key Normalization Points

* **No repeating groups** or multivalued attributes.
* **Each non-key attribute** depends only on the key.
* **Transitive dependencies** eliminated through proper table separation.

### 🔹 Bridge Tables (Many-to-Many)

* `MovieGenre` → connects movies and genres
* `MovieCast` → connects movies and people (actors/directors)

### 🔹 Keys & Constraints

* **Surrogate Primary Keys:** BIGINT auto-increment for all tables.
* **Natural Unique Keys:** user email, screen name per theatre, etc.
* **Cascading Rules:**

  * Deleting a `Show` cascades to `ShowSeat` and `Ticket`.
  * `Booking` deletion restricted unless status is *CANCELLED*.

---

## 📜 Business Rules

* 🎫 **Seat Booking Constraint:**
  A seat can be booked only once per show.

* 💰 **Booking Amount Calculation:**

  ```
  Total = SUM(ticket_price) + taxes – discounts
  ```

* ⚠️ **Payment Handling:**
  If payment fails, the booking remains **PENDING**, and seats automatically **time out** after a set window (demonstrated via trigger).

* 🧾 **Review Policy:**
  Only users who have attended a show may leave a review (enforced via foreign keys + app logic).

* 🔐 **Data Integrity:**
  Each booking is transactionally handled, ensuring consistent updates to seats, tickets, and payments.

---

## 🧱 What’s Implemented

| Feature               | Description                                                                                    |
| --------------------- | ---------------------------------------------------------------------------------------------- |
| **DDL**               | Tables with full `PRIMARY KEY`, `FOREIGN KEY`, and `CHECK` constraints (emulated via triggers) |
| **Indexes**           | Optimized for filtering and joins (movie title, show time, user activity)                      |
| **Triggers**          | For seat availability, auto timeout, and audit logs                                            |
| **Views**             | Analytical views for movie performance and theatre KPIs                                        |
| **Stored Procedures** | Transactional booking and reusable operations                                                  |
| **Advanced SQL**      | Includes CTEs, window functions, and pivot-like aggregates                                     |
| **Sample Data**       | Realistic data for cities, theatres, movies, users, and reviews                                |

---

## 📊 Sample Analytics Queries

Some queries included in `queries.sql`:

* 🎟️ **Top 5 Movies by Tickets Sold**
* 💸 **Revenue by Theatre and City**
* ⭐ **Average Movie Ratings**
* ⏰ **Upcoming Shows by Theatre**
* 👥 **Active Subscribers by Plan**
* 🧮 **Monthly Revenue Trend (Window Function)**

---

## 🧾 Sample Data

Seed data provides:

* Multiple **cities** and **theatres**
* A few **movies** and **shows**
* **Registered users** with active subscriptions
* **Sample reviews and payments** for analytics

This ensures all reporting queries return **meaningful and realistic results**.

---

## 🧠 Learning Outcomes

By exploring this project, you’ll learn to:

* ✅ Design and normalize a **real-world relational schema**
* ✅ Implement **Primary/Foreign Keys** and enforce data integrity
* ✅ Create and use **Triggers** for automation
* ✅ Write reusable **Views**, **Procedures**, and **Functions**
* ✅ Use **CTEs** and **Window Functions** for advanced SQL analytics
* ✅ Apply **indexes** and **optimization** for performance tuning

---



**Author:** *Shreya*
📚 *IIIT Nagpur — DBMS Project*

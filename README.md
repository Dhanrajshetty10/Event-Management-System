# 🎪 EventSphere — Event Management System
**DBMS Project | Node.js + MySQL**

---

## 📁 Project Structure
```
event-mgmt/
├── backend/
│   ├── server.js              # Express app entry point
│   ├── db.js                  # MySQL connection pool
│   ├── .env                   # DB credentials (edit this)
│   ├── package.json
│   ├── middleware/
│   │   └── auth.js            # JWT authentication
│   └── routes/
│       ├── auth.js            # Login / Register
│       ├── events.js          # Events CRUD + views
│       ├── registrations.js   # Register for events + feedback
│       ├── venues.js          # Venues
│       └── analytics.js       # Dashboard + advanced queries
├── frontend/
│   └── public/
│       └── index.html         # Single-page frontend
└── database/
    ├── schema.sql             # DDL: tables, views, grants, indexes
    ├── seed.sql               # Sample data
    └── queries.sql            # Advanced SQL queries (for viva)
```

---

## ⚙️ Setup Instructions

### 1. Install MySQL & create DB
```bash
mysql -u root -p < database/schema.sql
mysql -u root -p event_management < database/seed.sql
```

### 2. Configure environment
Edit `backend/.env`:
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=event_management
JWT_SECRET=any_secret_key
PORT=3000
```

### 3. Install and run backend
```bash
cd backend
npm install
npm start          # or: npm run dev (with nodemon)
```

### 4. Open in browser
```
http://localhost:3000
```

---

## 🔐 Demo Login Credentials
| Role      | Email               | Password    |
|-----------|---------------------|-------------|
| Admin     | admin@event.com     | password123 |
| Organizer | rahul@event.com     | password123 |
| Attendee  | aditya@event.com    | password123 |

> **Note:** Run `seed.sql` and hash passwords properly before first login, or update the hash in seed.sql. For demo, you can bypass bcrypt by temporarily using plain-text comparison.

---

## 🗄️ SQL Concepts Covered

### ✅ DDL (Data Definition Language)
- `CREATE TABLE` with constraints: PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL, CHECK, DEFAULT
- `CREATE INDEX` for performance
- `CREATE VIEW` — 5 views created

### ✅ DML (Data Manipulation Language)
- `INSERT`, `SELECT`, `UPDATE`, `DELETE`
- `INSERT ... SELECT`, `UPDATE ... JOIN`, `DELETE` with subquery
- Conditional `UPDATE` using `CASE`

### ✅ VIEWs
| View | Purpose |
|------|---------|
| `vw_event_details` | Full event info via JOINs |
| `vw_registration_details` | Registrations with user+event |
| `vw_event_stats` | Aggregates per event |
| `vw_upcoming_events` | Filtered view of upcoming events |
| `vw_top_attendees` | Top users by events attended |

### ✅ GRANT (Privileges)
- `event_admin` — Full access
- `event_org` — SELECT/INSERT/UPDATE on events & registrations
- `event_readonly` — SELECT on views only

### ✅ JOINs
- INNER JOIN, LEFT JOIN, Multiple JOINs, SELF JOIN, RIGHT JOIN

### ✅ Aggregate Functions
- `COUNT`, `SUM`, `AVG`, `MAX`, `MIN`
- `GROUP BY` with `HAVING`

### ✅ String Functions
- `UPPER`, `LOWER`, `LENGTH`, `SUBSTRING`, `CONCAT`, `REPLACE`, `TRIM`, `LIKE`, `LOCATE`, `DATE_FORMAT`

### ✅ UNION / SET Operations
- `UNION`, `UNION ALL`
- Simulated `INTERSECT` (NOT IN)
- Simulated `EXCEPT/MINUS` (NOT IN)

### ✅ Subqueries
- Scalar subquery, Correlated subquery, `EXISTS`, `NOT EXISTS`

### ✅ Constraints & Referential Integrity
- `ON DELETE CASCADE`, `ON DELETE RESTRICT`, `ON UPDATE CASCADE`
- CHECK constraints on phone, rating, price, capacity, time

### ✅ Advanced DML (Expt 6)
- Multi-table UPDATE with JOIN
- DELETE using subquery
- Conditional UPDATE with CASE

---

## 🌐 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/auth/register | Register user |
| POST | /api/auth/login | Login |
| GET | /api/events | All events (filterable) |
| GET | /api/events/upcoming | Upcoming events (via VIEW) |
| GET | /api/events/stats | Event stats (via VIEW + aggregates) |
| GET | /api/events/summary | Dashboard summary |
| GET | /api/events/:id | Single event + speakers + stats |
| POST | /api/events | Create event |
| PUT | /api/events/:id | Update event |
| DELETE | /api/events/:id | Delete event |
| GET | /api/events/:id/attendees | Event attendees (JOIN) |
| POST | /api/registrations | Register for event |
| GET | /api/registrations/my | My registrations |
| PUT | /api/registrations/:id/pay | Mark payment |
| DELETE | /api/registrations/:id | Cancel registration |
| GET | /api/venues | All venues |
| POST | /api/venues | Add venue |
| GET | /api/analytics/dashboard | Full analytics (UNION + aggregates) |
| GET | /api/analytics/top-attendees | Top attendees |
| GET | /api/analytics/events-no-registration | Events with no registrations (NOT IN) |
| GET | /api/analytics/events-no-feedback | Completed events without feedback (NOT EXISTS) |

---

## 📋 Tables
- `users` — System users (admin, organizer, attendee)
- `venues` — Event venues
- `events` — Core event records
- `registrations` — User-event registrations
- `feedback` — Post-event ratings and reviews
- `speakers` — Speaker profiles
- `event_speakers` — Many-to-many: events ↔ speakers

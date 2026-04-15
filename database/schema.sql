-- ============================================================
--  EVENT MANAGEMENT SYSTEM — DATABASE SCHEMA
--  DBMS Project | Covers: DDL, Constraints, Referential Integrity,
--  VIEWs, GRANT, Indexes
-- ============================================================

CREATE DATABASE IF NOT EXISTS event_management;
USE event_management;

-- ============================================================
-- TABLE 1: USERS
-- Constraints: PRIMARY KEY, NOT NULL, UNIQUE, CHECK
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    user_id     INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE,
    phone       VARCHAR(15),
    role        ENUM('admin', 'organizer', 'attendee') NOT NULL DEFAULT 'attendee',
    password    VARCHAR(255) NOT NULL,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_phone CHECK (phone REGEXP '^[0-9]{10}$' OR phone IS NULL)
);

-- ============================================================
-- TABLE 2: VENUES
-- Constraints: PRIMARY KEY, NOT NULL, CHECK
-- ============================================================
CREATE TABLE IF NOT EXISTS venues (
    venue_id    INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(150) NOT NULL,
    location    VARCHAR(255) NOT NULL,
    capacity    INT NOT NULL,
    city        VARCHAR(100) NOT NULL,
    contact     VARCHAR(15),
    CONSTRAINT chk_capacity CHECK (capacity > 0)
);

-- ============================================================
-- TABLE 3: EVENTS
-- Constraints: PRIMARY KEY, FOREIGN KEY (referential integrity),
--              NOT NULL, CHECK, DEFAULT
-- ============================================================
CREATE TABLE IF NOT EXISTS events (
    event_id        INT AUTO_INCREMENT PRIMARY KEY,
    title           VARCHAR(200) NOT NULL,
    description     TEXT,
    event_date      DATE NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    venue_id        INT NOT NULL,
    organizer_id    INT NOT NULL,
    category        ENUM('conference','workshop','concert','sports','cultural','other') NOT NULL DEFAULT 'other',
    max_capacity    INT NOT NULL,
    ticket_price    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status          ENUM('upcoming','ongoing','completed','cancelled') NOT NULL DEFAULT 'upcoming',
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,

    -- Referential Integrity (FOREIGN KEY)
    CONSTRAINT fk_event_venue     FOREIGN KEY (venue_id)     REFERENCES venues(venue_id)    ON DELETE RESTRICT  ON UPDATE CASCADE,
    CONSTRAINT fk_event_organizer FOREIGN KEY (organizer_id) REFERENCES users(user_id)      ON DELETE RESTRICT  ON UPDATE CASCADE,
    CONSTRAINT chk_ticket_price   CHECK (ticket_price >= 0),
    CONSTRAINT chk_max_capacity   CHECK (max_capacity > 0),
    CONSTRAINT chk_event_time     CHECK (end_time > start_time)
);

-- ============================================================
-- TABLE 4: REGISTRATIONS
-- Constraints: PRIMARY KEY, FOREIGN KEY, UNIQUE composite, CHECK
-- ============================================================
CREATE TABLE IF NOT EXISTS registrations (
    reg_id          INT AUTO_INCREMENT PRIMARY KEY,
    event_id        INT NOT NULL,
    user_id         INT NOT NULL,
    registered_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    payment_status  ENUM('pending','paid','refunded') NOT NULL DEFAULT 'pending',
    amount_paid     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    seat_number     INT,

    CONSTRAINT fk_reg_event  FOREIGN KEY (event_id) REFERENCES events(event_id)  ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reg_user   FOREIGN KEY (user_id)  REFERENCES users(user_id)    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_reg        UNIQUE (event_id, user_id),   -- one registration per user per event
    CONSTRAINT chk_amount    CHECK (amount_paid >= 0)
);

-- ============================================================
-- TABLE 5: FEEDBACK
-- Constraints: PRIMARY KEY, FOREIGN KEY, CHECK (rating range)
-- ============================================================
CREATE TABLE IF NOT EXISTS feedback (
    feedback_id     INT AUTO_INCREMENT PRIMARY KEY,
    event_id        INT NOT NULL,
    user_id         INT NOT NULL,
    rating          TINYINT NOT NULL,
    comments        TEXT,
    submitted_at    DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_fb_event  FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fb_user   FOREIGN KEY (user_id)  REFERENCES users(user_id)   ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_rating   CHECK (rating BETWEEN 1 AND 5)
);

-- ============================================================
-- TABLE 6: SPEAKERS (for conferences/workshops)
-- Constraints: PRIMARY KEY, NOT NULL
-- ============================================================
CREATE TABLE IF NOT EXISTS speakers (
    speaker_id  INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    bio         TEXT,
    expertise   VARCHAR(200),
    email       VARCHAR(150) UNIQUE
);

-- ============================================================
-- TABLE 7: EVENT_SPEAKERS (Many-to-Many)
-- Constraints: Composite PRIMARY KEY, FOREIGN KEY
-- ============================================================
CREATE TABLE IF NOT EXISTS event_speakers (
    event_id    INT NOT NULL,
    speaker_id  INT NOT NULL,
    PRIMARY KEY (event_id, speaker_id),
    CONSTRAINT fk_es_event   FOREIGN KEY (event_id)   REFERENCES events(event_id)   ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_es_speaker FOREIGN KEY (speaker_id) REFERENCES speakers(speaker_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- INDEXES (for query performance)
-- ============================================================
CREATE INDEX idx_events_date     ON events(event_date);
CREATE INDEX idx_events_category ON events(category);
CREATE INDEX idx_reg_event       ON registrations(event_id);
CREATE INDEX idx_reg_user        ON registrations(user_id);


-- ============================================================
-- VIEWS
-- ============================================================

-- VIEW 1: Full event details with venue and organizer info (JOIN-based)
CREATE OR REPLACE VIEW vw_event_details AS
SELECT
    e.event_id,
    e.title,
    e.description,
    e.event_date,
    e.start_time,
    e.end_time,
    e.category,
    e.ticket_price,
    e.max_capacity,
    e.status,
    v.name       AS venue_name,
    v.location   AS venue_location,
    v.city       AS venue_city,
    v.capacity   AS venue_capacity,
    u.name       AS organizer_name,
    u.email      AS organizer_email
FROM events e
JOIN venues v ON e.venue_id   = v.venue_id
JOIN users  u ON e.organizer_id = u.user_id;

-- VIEW 2: Registration summary with event + user info
CREATE OR REPLACE VIEW vw_registration_details AS
SELECT
    r.reg_id,
    r.registered_at,
    r.payment_status,
    r.amount_paid,
    r.seat_number,
    e.title      AS event_title,
    e.event_date,
    u.name       AS attendee_name,
    u.email      AS attendee_email
FROM registrations r
JOIN events e ON r.event_id = e.event_id
JOIN users  u ON r.user_id  = u.user_id;

-- VIEW 3: Aggregate stats per event (Aggregate functions)
CREATE OR REPLACE VIEW vw_event_stats AS
SELECT
    e.event_id,
    e.title,
    e.event_date,
    e.max_capacity,
    COUNT(r.reg_id)            AS total_registrations,
    SUM(r.amount_paid)         AS total_revenue,
    AVG(r.amount_paid)         AS avg_ticket_price,
    MAX(r.amount_paid)         AS max_paid,
    MIN(r.amount_paid)         AS min_paid,
    ROUND(AVG(f.rating), 2)   AS avg_rating,
    COUNT(DISTINCT f.feedback_id) AS total_feedback,
    (e.max_capacity - COUNT(r.reg_id)) AS seats_remaining
FROM events e
LEFT JOIN registrations r ON e.event_id = r.event_id
LEFT JOIN feedback      f ON e.event_id = f.event_id
GROUP BY e.event_id, e.title, e.event_date, e.max_capacity;

-- VIEW 4: Upcoming events only
CREATE OR REPLACE VIEW vw_upcoming_events AS
SELECT * FROM vw_event_details
WHERE event_date >= CURDATE() AND status = 'upcoming';

-- VIEW 5: Top attendees by events attended
CREATE OR REPLACE VIEW vw_top_attendees AS
SELECT
    u.user_id,
    u.name,
    u.email,
    COUNT(r.reg_id)   AS events_attended,
    SUM(r.amount_paid) AS total_spent
FROM users u
JOIN registrations r ON u.user_id = r.user_id
GROUP BY u.user_id, u.name, u.email
ORDER BY events_attended DESC;


-- ============================================================
-- GRANT PERMISSIONS
-- ============================================================

-- Create application users with specific privileges
CREATE USER IF NOT EXISTS 'event_admin'@'localhost'   IDENTIFIED BY 'Admin@1234';
CREATE USER IF NOT EXISTS 'event_org'@'localhost'     IDENTIFIED BY 'Org@1234';
CREATE USER IF NOT EXISTS 'event_readonly'@'localhost' IDENTIFIED BY 'Read@1234';

-- Admin: Full access
GRANT ALL PRIVILEGES ON event_management.* TO 'event_admin'@'localhost';

-- Organizer: Can manage events and registrations, read users
GRANT SELECT, INSERT, UPDATE ON event_management.events        TO 'event_org'@'localhost';
GRANT SELECT, INSERT, UPDATE ON event_management.registrations TO 'event_org'@'localhost';
GRANT SELECT                  ON event_management.users         TO 'event_org'@'localhost';
GRANT SELECT                  ON event_management.venues        TO 'event_org'@'localhost';
GRANT SELECT                  ON event_management.vw_event_stats TO 'event_org'@'localhost';

-- Read-only user: Can only SELECT views
GRANT SELECT ON event_management.vw_event_details     TO 'event_readonly'@'localhost';
GRANT SELECT ON event_management.vw_upcoming_events   TO 'event_readonly'@'localhost';
GRANT SELECT ON event_management.vw_event_stats       TO 'event_readonly'@'localhost';
GRANT SELECT ON event_management.vw_registration_details TO 'event_readonly'@'localhost';

FLUSH PRIVILEGES;

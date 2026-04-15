-- ============================================================
--  SEED DATA — Event Management System
-- ============================================================
USE event_management;

-- Users (passwords are bcrypt of 'password123')
INSERT INTO users (name, email, phone, role, password) VALUES
('Admin User',       'admin@event.com',     '9876543210', 'admin',     'password123'),
('Rahul Sharma',     'rahul@event.com',     '9812345678', 'organizer', 'password123'),
('Priya Patel',      'priya@event.com',     '9823456789', 'organizer', 'password123'),
('Aditya Kumar',     'aditya@event.com',    '9834567890', 'attendee',  'password123'),
('Sneha Desai',      'sneha@event.com',     '9845678901', 'attendee',  'password123'),
('Mohd Tazim',       'tazim@event.com',     '9856789012', 'attendee',  'password123'),
('Anjali Singh',     'anjali@event.com',    '9867890123', 'attendee',  'password123'),
('Vikram Nair',      'vikram@event.com',    '9878901234', 'organizer', 'password123');

-- Venues
INSERT INTO venues (name, location, capacity, city, contact) VALUES
('Tech Hub Auditorium',  'Andheri East, Near Metro',    500, 'Mumbai',    '9900001111'),
('Green Valley Ground',  'Powai Lake Road',             2000, 'Mumbai',   '9900002222'),
('Innovate Center',      'Bandra Kurla Complex',        300, 'Mumbai',    '9900003333'),
('City Convention Hall', 'Bhiwandi Industrial Area',    800, 'Bhiwandi',  '9900004444'),
('Open Air Arena',       'Thane West, Upvan Lake',     1500, 'Thane',     '9900005555');

-- Speakers
INSERT INTO speakers (name, bio, expertise, email) VALUES
('Dr. Arjun Mehta',  'IIT Professor with 20 years in AI',    'Artificial Intelligence, ML', 'arjun@iit.ac.in'),
('Ms. Ritu Khanna',  'Award-winning startup founder',         'Entrepreneurship, FinTech',   'ritu@startup.io'),
('Mr. Dev Pillai',   'Cloud architect at MNC',                'Cloud Computing, DevOps',     'dev@cloud.com'),
('Dr. Nisha Roy',    'Cybersecurity expert, ex-ISRO',         'Cybersecurity, Networks',     'nisha@sec.org');

-- Events
INSERT INTO events (title, description, event_date, start_time, end_time, venue_id, organizer_id, category, max_capacity, ticket_price, status) VALUES
('AI & Future Tech Summit 2025',   'Annual tech conference on AI, ML, and automation',            '2025-08-15', '09:00:00', '18:00:00', 1, 2, 'conference', 400, 1500.00, 'upcoming'),
('Startup Pitch Night',            'Top 20 startups pitch to investors. Networking included.',    '2025-07-20', '17:00:00', '21:00:00', 3, 3, 'other',      250, 500.00,  'upcoming'),
('Rock Fest Mumbai 2025',          'Live performances by 10 top rock bands of India.',            '2025-09-05', '15:00:00', '23:00:00', 2, 8, 'concert',   1500, 2000.00, 'upcoming'),
('Cloud & DevOps Workshop',        'Hands-on workshop on AWS, Docker, Kubernetes.',               '2025-07-10', '10:00:00', '17:00:00', 1, 2, 'workshop',  100, 800.00,  'upcoming'),
('Bhiwandi Cultural Night',        'Celebrating local culture with dance, music, and food.',      '2025-06-28', '18:00:00', '22:00:00', 4, 3, 'cultural',  600, 200.00,  'upcoming'),
('Cybersecurity Awareness Talk',   'Free public talk on staying safe online.',                    '2025-06-10', '11:00:00', '14:00:00', 3, 8, 'conference',200, 0.00,    'completed'),
('Thane Sports Carnival',          'Inter-college sports competitions.',                          '2025-05-15', '08:00:00', '20:00:00', 5, 2, 'sports',   1000, 100.00,  'completed');

-- Event Speakers (many-to-many)
INSERT INTO event_speakers (event_id, speaker_id) VALUES
(1, 1), (1, 3),  -- AI Summit: Dr. Arjun + Dev Pillai
(2, 2),          -- Startup Night: Ritu Khanna
(4, 3),          -- Cloud Workshop: Dev Pillai
(6, 4);          -- Cybersecurity: Dr. Nisha Roy

-- Registrations
INSERT INTO registrations (event_id, user_id, payment_status, amount_paid, seat_number) VALUES
(1, 4, 'paid',    1500.00, 1),
(1, 5, 'paid',    1500.00, 2),
(1, 6, 'paid',    1500.00, 3),
(1, 7, 'pending', 0.00,    NULL),
(2, 4, 'paid',    500.00,  1),
(2, 6, 'paid',    500.00,  2),
(3, 5, 'paid',    2000.00, 1),
(3, 7, 'paid',    2000.00, 2),
(4, 4, 'paid',    800.00,  1),
(4, 5, 'paid',    800.00,  2),
(5, 6, 'paid',    200.00,  1),
(5, 7, 'paid',    200.00,  2),
(6, 4, 'paid',    0.00,    1),
(6, 6, 'paid',    0.00,    2),
(7, 5, 'paid',    100.00,  1),
(7, 7, 'refunded',100.00,  2);

-- Feedback
INSERT INTO feedback (event_id, user_id, rating, comments) VALUES
(6, 4, 5, 'Excellent talk! Very informative and practical.'),
(6, 6, 4, 'Good content, venue could be better.'),
(7, 5, 4, 'Great event! Loved the sports carnival atmosphere.'),
(7, 7, 3, 'Okay, but could have had better organization.');

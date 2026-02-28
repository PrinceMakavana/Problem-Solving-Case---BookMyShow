-- BookMyShow Theatre Scheduling Assignment
-- Portable SQL that runs on MySQL 8+ and SQLite-style runners
-- If using MySQL and a dedicated DB:

CREATE DATABASE IF NOT EXISTS bookmyshow_db;
USE bookmyshow_db;

-- Drop tables in reverse dependency order for repeatable runs
DROP TABLE IF EXISTS shows;
DROP TABLE IF EXISTS screens;
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS theatres;

-- 1) theatres
CREATE TABLE theatres (
    theatre_id BIGINT PRIMARY KEY,
    theatre_name VARCHAR(120) NOT NULL,
    city VARCHAR(80) NOT NULL,
    address_line VARCHAR(255) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2) screens
CREATE TABLE screens (
    screen_id BIGINT PRIMARY KEY,
    theatre_id BIGINT NOT NULL,
    screen_name VARCHAR(40) NOT NULL,
    total_seats INT NOT NULL,
    CONSTRAINT fk_screens_theatre
        FOREIGN KEY (theatre_id) REFERENCES theatres(theatre_id),
    CONSTRAINT uq_screens_theatre_screen
        UNIQUE (theatre_id, screen_name)
);

-- 3) movies
CREATE TABLE movies (
    movie_id BIGINT PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    language VARCHAR(40) NOT NULL,
    certificate VARCHAR(10) NOT NULL,
    duration_mins SMALLINT NOT NULL,
    release_date DATE NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1
);

-- 4) shows
CREATE TABLE shows (
    show_id BIGINT PRIMARY KEY,
    screen_id BIGINT NOT NULL,
    movie_id BIGINT NOT NULL,
    show_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    base_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(10) NOT NULL DEFAULT 'SCHEDULED',
    CONSTRAINT fk_shows_screen
        FOREIGN KEY (screen_id) REFERENCES screens(screen_id),
    CONSTRAINT fk_shows_movie
        FOREIGN KEY (movie_id) REFERENCES movies(movie_id),
    CONSTRAINT uq_shows_screen_date_start
        UNIQUE (screen_id, show_date, start_time),
    CONSTRAINT chk_shows_status
        CHECK (status IN ('SCHEDULED', 'CANCELLED'))
);

CREATE INDEX idx_shows_show_date ON shows (show_date);
CREATE INDEX idx_shows_screen_date ON shows (screen_id, show_date);

-- Sample data
INSERT INTO theatres (theatre_id, theatre_name, city, address_line, is_active) VALUES
(101, 'Cinepolis Nexus Mall', 'Bengaluru', 'Nexus Mall, Koramangala', 1),
(102, 'PVR Orion Avenue', 'Bengaluru', 'Orion Avenue, Rajajinagar', 1);

INSERT INTO screens (screen_id, theatre_id, screen_name, total_seats) VALUES
(201, 101, 'Screen 1', 180),
(202, 101, 'Screen 2', 140),
(203, 102, 'Audi 1', 220),
(204, 102, 'Audi 2', 160);

INSERT INTO movies (movie_id, title, language, certificate, duration_mins, release_date, is_active) VALUES
(301, 'Now You See Me: Now You Don''t', 'English', 'UA', 128, '2026-02-14', 1),
(302, 'Thama', 'Hindi', 'U', 142, '2026-01-30', 1),
(303, 'Mirai', 'Japanese', 'UA', 116, '2026-02-21', 1),
(304, 'Toxic', 'Kannada', 'A', 134, '2026-02-07', 1),
(305, 'Sisu', 'English', 'A', 110, '2026-02-28', 1),
(306, 'Nobody', 'English', 'A', 92, '2026-02-10', 1);

INSERT INTO shows (show_id, screen_id, movie_id, show_date, start_time, end_time, base_price, status) VALUES
(401, 201, 301, '2026-03-01', '09:00:00', '11:08:00', 220.00, 'SCHEDULED'),
(402, 201, 302, '2026-03-01', '12:00:00', '14:22:00', 250.00, 'SCHEDULED'),
(403, 202, 304, '2026-03-01', '10:15:00', '12:29:00', 200.00, 'SCHEDULED'),
(404, 202, 305, '2026-03-01', '15:00:00', '16:50:00', 180.00, 'CANCELLED'),
(405, 203, 303, '2026-03-01', '11:30:00', '13:26:00', 280.00, 'SCHEDULED'),
(406, 204, 306, '2026-03-01', '14:00:00', '15:32:00', 260.00, 'SCHEDULED'),
(407, 201, 303, '2026-03-02', '09:30:00', '11:26:00', 230.00, 'SCHEDULED'),
(408, 202, 301, '2026-03-02', '13:00:00', '15:08:00', 220.00, 'SCHEDULED'),
(409, 203, 302, '2026-03-02', '10:00:00', '12:22:00', 270.00, 'SCHEDULED'),
(410, 204, 304, '2026-03-02', '18:00:00', '20:14:00', 240.00, 'SCHEDULED');

-- P2 query (parameterized style)
-- Inputs: :theatre_id, :target_date
SELECT
    t.theatre_name,
    m.title AS movie_title,
    sc.screen_name,
    s.show_date,
    s.start_time,
    s.end_time,
    s.status
FROM shows s
JOIN screens sc ON sc.screen_id = s.screen_id
JOIN theatres t ON t.theatre_id = sc.theatre_id
JOIN movies m ON m.movie_id = s.movie_id
WHERE sc.theatre_id = :theatre_id
  AND s.show_date = :target_date
  AND s.status = 'SCHEDULED'
ORDER BY s.start_time ASC;

-- Literal runnable variant of P2
SELECT
    t.theatre_name,
    m.title AS movie_title,
    sc.screen_name,
    s.show_date,
    s.start_time,
    s.end_time,
    s.status
FROM shows s
JOIN screens sc ON sc.screen_id = s.screen_id
JOIN theatres t ON t.theatre_id = sc.theatre_id
JOIN movies m ON m.movie_id = s.movie_id
WHERE sc.theatre_id = 101
  AND s.show_date = '2026-03-01'
  AND s.status = 'SCHEDULED'
ORDER BY s.start_time ASC;

-- Validation scenarios

-- 1) Valid theatre/date with multiple shows
SELECT s.show_id, sc.screen_name, m.title, s.start_time, s.end_time, s.status
FROM shows s
JOIN screens sc ON sc.screen_id = s.screen_id
JOIN movies m ON m.movie_id = s.movie_id
WHERE sc.theatre_id = 101 AND s.show_date = '2026-03-01'
ORDER BY s.start_time;

-- 2) Valid theatre/date with no shows
SELECT s.show_id
FROM shows s
JOIN screens sc ON sc.screen_id = s.screen_id
WHERE sc.theatre_id = 101 AND s.show_date = '2026-03-10';

-- 3) Different theatre same date
SELECT s.show_id, sc.screen_name, m.title, s.start_time
FROM shows s
JOIN screens sc ON sc.screen_id = s.screen_id
JOIN movies m ON m.movie_id = s.movie_id
WHERE sc.theatre_id = 102 AND s.show_date = '2026-03-01'
ORDER BY s.start_time;

-- 4) Collision prevention test (should fail: duplicate screen/date/start_time)
-- INSERT INTO shows (show_id, screen_id, movie_id, show_date, start_time, end_time, base_price, status)
-- VALUES (411, 201, 305, '2026-03-01', '09:00:00', '10:50:00', 210.00, 'SCHEDULED');

-- 5) Referential integrity tests (should fail)
-- INSERT INTO shows (show_id, screen_id, movie_id, show_date, start_time, end_time, base_price, status)
-- VALUES (412, 999, 301, '2026-03-03', '09:00:00', '11:08:00', 200.00, 'SCHEDULED');

-- INSERT INTO shows (show_id, screen_id, movie_id, show_date, start_time, end_time, base_price, status)
-- VALUES (413, 201, 999, '2026-03-03', '12:00:00', '14:08:00', 200.00, 'SCHEDULED');

# BookMyShow Theatre Scheduling Assignment

## P1. Entities, Attributes, Table Structures, SQL, and Sample Data

### Scope
Core scheduling only:
- Theatre
- Screen
- Movie
- Show

### Entity List and Attributes

1. `theatres`
- `theatre_id` (BIGINT, PK)
- `theatre_name` (VARCHAR(120), NOT NULL)
- `city` (VARCHAR(80), NOT NULL)
- `address_line` (VARCHAR(255), NOT NULL)
- `is_active` (TINYINT(1), NOT NULL, default `1`)
- `created_at` (DATETIME, NOT NULL, default `CURRENT_TIMESTAMP`)

2. `screens`
- `screen_id` (BIGINT, PK)
- `theatre_id` (BIGINT, FK -> `theatres.theatre_id`)
- `screen_name` (VARCHAR(40), NOT NULL)
- `total_seats` (INT, NOT NULL)
- Unique: (`theatre_id`, `screen_name`)

3. `movies`
- `movie_id` (BIGINT, PK)
- `title` (VARCHAR(150), NOT NULL)
- `language` (VARCHAR(40), NOT NULL)
- `certificate` (VARCHAR(10), NOT NULL)
- `duration_mins` (SMALLINT, NOT NULL)
- `release_date` (DATE, NULL)
- `is_active` (TINYINT(1), NOT NULL, default `1`)

4. `shows`
- `show_id` (BIGINT, PK)
- `screen_id` (BIGINT, FK -> `screens.screen_id`)
- `movie_id` (BIGINT, FK -> `movies.movie_id`)
- `show_date` (DATE, NOT NULL)
- `start_time` (TIME, NOT NULL)
- `end_time` (TIME, NOT NULL)
- `base_price` (DECIMAL(10,2), NOT NULL)
- `status` (VARCHAR(10), NOT NULL, default `SCHEDULED`, checked to allowed values)
- Unique: (`screen_id`, `show_date`, `start_time`)
- Indexes: (`show_date`), (`screen_id`, `show_date`)

---

### SQL (MySQL 8+)

The full executable SQL is provided in:
- `bookmyshow_assignment.sql`

It includes:
1. `CREATE DATABASE` + `USE`
2. `CREATE TABLE` statements in FK-safe order
3. Sample inserts
4. P2 query
5. Validation/test queries

---

### Sample Rows (few examples)

#### `theatres`
| theatre_id | theatre_name            | city      | address_line               | is_active |
|---|---|---|---|---|
| 101 | Cinepolis Nexus Mall | Bengaluru | Nexus Mall, Koramangala | 1 |
| 102 | PVR Orion Avenue | Bengaluru | Orion Avenue, Rajajinagar | 1 |

#### `screens`
| screen_id | theatre_id | screen_name | total_seats |
|---|---|---|---|
| 201 | 101 | Screen 1 | 180 |
| 202 | 101 | Screen 2 | 140 |
| 203 | 102 | Audi 1 | 220 |

#### `movies`
| movie_id | title | language | certificate | duration_mins | release_date |
|---|---|---|---|---|---|
| 301 | Now You See Me: Now You Don't | English | UA | 128 | 2026-02-14 |
| 302 | Thama | Hindi | U | 142 | 2026-01-30 |
| 303 | Mirai | Japanese | UA | 116 | 2026-02-21 |

#### `shows`
| show_id | screen_id | movie_id | show_date | start_time | end_time | base_price | status |
|---|---|---|---|---|---|---|---|
| 401 | 201 | 301 | 2026-03-01 | 09:00:00 | 11:08:00 | 220.00 | SCHEDULED |
| 402 | 201 | 302 | 2026-03-01 | 12:00:00 | 14:22:00 | 250.00 | SCHEDULED |
| 404 | 202 | 305 | 2026-03-01 | 15:00:00 | 16:50:00 | 180.00 | CANCELLED |

---

### Normalization Proof

1. **1NF**
- Every column stores atomic values (`DATE`, `TIME`, numeric, scalar strings).
- No repeating groups or multi-valued columns.

2. **2NF**
- Primary keys are single-column surrogate keys (`*_id`), so partial dependency on composite PKs does not exist.
- Non-key attributes depend on the whole key only.

3. **3NF**
- No transitive dependency among non-key attributes.
- Example: theatre details are only in `theatres`; `shows` references theatre indirectly via `screens`.
- Movie metadata remains in `movies`, not duplicated in `shows`.

4. **BCNF**
- Every determinant is a candidate key.
- Determinants used:
  - `theatre_id` -> theatre attributes (PK)
  - `screen_id` -> screen attributes (PK)
  - (`theatre_id`, `screen_name`) -> screen row (UNIQUE candidate key)
  - `movie_id` -> movie attributes (PK)
  - `show_id` -> show attributes (PK)
  - (`screen_id`, `show_date`, `start_time`) -> show row (UNIQUE candidate key)

---

## P2. Query to List Shows for a Given Theatre and Date

### Parameterized Query

```sql
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
```

### Runnable Example

```sql
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
```

---

## Test Scenarios Covered in SQL File

1. Valid theatre/date with multiple shows.
2. Valid theatre/date with no shows.
3. Different theatre on same date.
4. Schedule collision insert (expected unique constraint failure).
5. Invalid foreign key inserts for `screen_id` / `movie_id` (expected FK failure).

---

## Assumptions and Defaults

1. Assignment scope excludes booking, seats, payments.
2. Local theatre time is used (no timezone conversion).
3. `end_time` is stored explicitly.
4. One show maps to one movie and one screen.
5. Constraints are enforced mainly through PK/FK/UNIQUE for broad MySQL compatibility.

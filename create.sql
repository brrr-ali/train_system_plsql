CREATE TABLE IF NOT EXISTS stations
(
    id           SERIAL PRIMARY KEY,
    station_name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS passengers
(
    passenger_id  SERIAL PRIMARY KEY,
    passport_info JSONB,
    email         VARCHAR(50),
    phone_number  VARCHAR(15)
);

CREATE TABLE IF NOT EXISTS positions
(
    id   SERIAL PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS crews
(
    id              SERIAL PRIMARY KEY,
    head_station_id INTEGER REFERENCES stations (id)
);

CREATE TABLE IF NOT EXISTS employees
(
    id                  SERIAL PRIMARY KEY,
    first_name          VARCHAR(50) NOT NULL,
    last_name           VARCHAR(50) NOT NULL,
    email               VARCHAR(50),
    phone_number        VARCHAR(15),
    position_id         INTEGER REFERENCES positions (id),
    manager_id          INTEGER REFERENCES employees (id),
    assigned_station_id INTEGER REFERENCES stations (id),
    crew_id             INTEGER REFERENCES crews (id) -- todo добавить ограничение на номер бригады, проверку является ли assigned_station_id = head_station
);

CREATE TABLE IF NOT EXISTS routes_info -- предполагаю что если существует из А в В, то и из В в А - и
-- для удобства отсчета в обратном порядке указываю порядковый номер последней станции
(
    route_id       SERIAL PRIMARY KEY,
    count_stations INT
);

CREATE TABLE IF NOT EXISTS routes
(
    route_id      INT REFERENCES routes_info (route_id),
    station_id    INT REFERENCES stations (id),
    distance      INT NOT NULL,
    station_order INT NOT NULL CHECK ( station_order > 0 ),
    PRIMARY KEY (route_id, station_order)
);

CREATE TABLE IF NOT EXISTS categories
(
    category_id   SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS wagon_types
(
    id              SERIAL PRIMARY KEY,
    type_name       VARCHAR(50) UNIQUE NOT NULL,
    max_seat_number integer -- считаю, что места нумеруются от 1 до max_seat_number
);

CREATE TABLE IF NOT EXISTS wagons
(
    id            SERIAL PRIMARY KEY,
    wagon_type_id INT REFERENCES wagon_types (id) NOT NULL
);

CREATE TABLE IF NOT EXISTS trains
(
    id              SERIAL PRIMARY KEY,
    train_number    VARCHAR(50) NOT NULL,
    category_id     INT REFERENCES categories (category_id),
    head_station_id INT REFERENCES stations (id),
    wagons_ids      integer[]
);

CREATE TYPE direction_enum AS ENUM ('прямое', 'обратное');

CREATE TABLE IF NOT EXISTS ride_info
(
    ride_id   SERIAL PRIMARY KEY,
    route_id  INT REFERENCES routes_info (route_id), -- из маршрута и направления можно вытащить головную станцию
    crew_id   INT REFERENCES crews (id),
    train_id  INT REFERENCES trains (id),
    direction direction_enum
);

CREATE TABLE IF NOT EXISTS tickets
(
    id                  SERIAL PRIMARY KEY,
    wagon_number        INTEGER, -- добавь проверку, что в этом поезде есть такой вагон
    seat_number         INTEGER, -- добавь проверку, что в этом вагоне есть такое место
    ride_id             INT REFERENCES ride_info (ride_id),
    start_station_order INT            NOT NULL,
    end_station_order   INT            NOT NULL,
    passenger_id        INT REFERENCES passengers (passenger_id),
    price               NUMERIC(10, 2) NOT NULL,
    CHECK (start_station_order < end_station_order)
);


CREATE TABLE IF NOT EXISTS timetable
(
    ride_id                INT REFERENCES ride_info (ride_id),
    station_order          INT,
    planned_arrival_time   TIMESTAMP,
    planned_departure_time TIMESTAMP,
    actual_arrival_time    TIMESTAMP,
    actual_departure_time  TIMESTAMP,
    PRIMARY KEY (ride_id, station_order),
    CHECK (planned_departure_time > planned_arrival_time AND timetable.actual_departure_time > actual_arrival_time)
);


CREATE INDEX if not exists idx_routes_info_route_id ON routes_info (route_id);
CREATE INDEX if not exists idx_ride_info_route_id ON ride_info(route_id);
CREATE INDEX if not exists idx_schedule_arrival_date ON timetable ((CAST(planned_arrival_time AS DATE)));
CREATE INDEX if not exists idx_tickets_ride_id ON tickets(ride_id);
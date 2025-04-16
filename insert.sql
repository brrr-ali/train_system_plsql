INSERT INTO routes_info (count_stations)
SELECT FLOOR(RANDOM() * 30) + 5
FROM generate_series(1, 5000);

DO
$$
    DECLARE
        route_record       RECORD;
        station_ids        INT[];
        current_station_id INT;
        current_distance   INT;
        current_order      INT;
    BEGIN
        FOR route_record IN SELECT route_id, count_stations FROM routes_info
            LOOP
                station_ids := ARRAY(
                        SELECT id
                        FROM stations
                        ORDER BY RANDOM()
                        LIMIT route_record.count_stations
                               );
                current_order := 1;
                current_distance := 0;
                FOREACH current_station_id IN ARRAY station_ids
                    LOOP
                        INSERT INTO routes (route_id, station_id, distance, station_order)
                        VALUES (route_record.route_id, current_station_id, current_distance, current_order);
                        current_order := current_order + 1;
                        current_distance := FLOOR(RANDOM() * 100) + 20;
                    END LOOP;
            END LOOP;
    END
$$;

INSERT INTO categories (category_name)
VALUES ('скорый пассажирский'),
       ('пассажирский'),
       ('грузовой');

INSERT INTO wagon_types (type_name, max_seat_number)
VALUES ('Сидячий', FLOOR(RANDOM() * 30) + 4),
       ('Плацкартный', FLOOR(RANDOM() * 30) + 4),
       ('Купейный', FLOOR(RANDOM() * 30) + 4),
       ('СВ (спальный)', FLOOR(RANDOM() * 30) + 4),
       ('Ресторанный', FLOOR(RANDOM() * 30) + 4);


INSERT INTO wagons (wagon_type_id)
SELECT FLOOR(RANDOM() * (SELECT max(id) - 1 from wagon_types) + 1)
FROM generate_series(1, 5000);



DO
$$
    DECLARE
        random_train_number varchar(30);
        count_trains        INT := 1000;
        head_stations       INT[];
        max_category_id     INT;

    BEGIN
        SELECT array_agg(id) INTO head_stations FROM stations ORDER BY random() LIMIT count_trains;

        max_category_id := (SELECT max(category_id) FROM categories);
        FOR i IN 1..count_trains
            LOOP
                random_train_number := FLOOR(RANDOM() * 90000) + 10000;

                INSERT INTO trains (train_number, category_id, head_station_id, wagons_ids)
                VALUES (random_train_number,
                        FLOOR(RANDOM() * max_category_id) + 1,
                        head_stations[i],
                        ARRAY(
                                SELECT id
                                FROM wagons
                                ORDER BY RANDOM()
                                LIMIT FLOOR(RANDOM() * 10) + 1));
            END LOOP;
    END
$$;


DO
$$
    DECLARE
        count_rides INT := 10000;
        max_crew    INT;
        max_train   INT;
        max_routes  INT;
    BEGIN
        SELECT max(id) from crews into max_crew;
        SELECT max(id) from trains into max_train;
        SELECT max(route_id) from routes_info into max_routes;
        FOR i IN 1..count_rides
            LOOP
                INSERT INTO ride_info (route_id, crew_id, train_id, direction)
                VALUES (FLOOR(RANDOM() * (max_routes - 1)) + 1,
                        FLOOR(RANDOM() * (max_crew - 1)) + 1,
                        FLOOR(RANDOM() * (max_train - 1)) + 1,
                        'прямое'),
                       (FLOOR(RANDOM() * (max_routes - 1)) + 1,
                        FLOOR(RANDOM() * (max_crew - 1)) + 1,
                        FLOOR(RANDOM() * (max_train - 1)) + 1,
                        'обратное');

            END LOOP;
    END
$$;


-- todo: написать оптимизированную версию, сейчас работало 13 минут - это много :(
DO
$$
    DECLARE
        ride_record    ride_info%ROWTYPE;
        train_record   trains%ROWTYPE;
        route_record   routes_info%ROWTYPE;
        wagon_id       INT;
        wagon_number   INT;
        seat_number    INT;
        max_seat       INT;
        stations_count INT;
        start_order    INT;
        end_order      INT;
        last_end       INT;
        iterations     INT;
        passenger_ids  INT[];
        i              INT := 1;
    BEGIN
        FOR ride_record IN SELECT * FROM ride_info
            LOOP
                SELECT * INTO train_record FROM trains WHERE id = ride_record.train_id;
                SELECT * INTO route_record FROM routes_info WHERE route_id = ride_record.route_id;
                stations_count := route_record.count_stations;
                SELECT array_agg(passenger_id) INTO passenger_ids FROM passengers ORDER BY random();

                FOR wagon_number IN 1..array_length(train_record.wagons_ids, 1)
                    LOOP
                        wagon_id := train_record.wagons_ids[wagon_number];
                        SELECT max_seat_number
                        INTO max_seat
                        FROM wagons
                                 JOIN public.wagon_types on wagons.wagon_type_id = wagon_types.id
                        WHERE wagons.id = wagon_id;

                        FOR seat_number IN 1..max_seat by FLOOR(random() * 10) + 1
                            LOOP
                                last_end := 0;
                                iterations := 0;
                                WHILE last_end < stations_count - 1 AND iterations < 4
                                    LOOP
                                        start_order := last_end + 1 + floor(random() * 2)::int;
                                        IF start_order > stations_count - 1 THEN
                                            start_order := stations_count - 1;
                                        END IF;
                                        end_order := start_order + 1 +
                                                     floor(random() * (stations_count - start_order - 1))::int;
                                        IF ride_record.direction = 'обратное' THEN
                                            start_order := stations_count - start_order + 1;
                                            end_order := stations_count - end_order + 1;
                                            -- Меняем местами для сохранения условия start < end
                                            IF start_order > end_order THEN
                                                SELECT end_order, start_order INTO start_order, end_order;
                                            END IF;
                                        END IF;

                                        INSERT INTO tickets (wagon_number,
                                                             seat_number,
                                                             ride_id,
                                                             start_station_order,
                                                             end_station_order, passenger_id, price)
                                        VALUES (wagon_number,
                                                seat_number,
                                                ride_record.ride_id,
                                                start_order,
                                                end_order, passenger_ids[i],
                                                (500 + random() * 30000)::numeric(10, 2));
                                        i := i + 1;
                                        last_end := end_order;
                                        iterations := iterations + 1;
                                    END LOOP;
                            END LOOP;
                    END LOOP;
            END LOOP;
    END
$$;


DO
$$
    DECLARE
        ride_rec        ride_info%ROWTYPE;
        route_rec       routes%ROWTYPE;
        base_time       TIMESTAMP;
        station_time    TIMESTAMP;
        direction_order INT;
        station_counter INT;
        total_stations  INT;
        delay           INT;
    BEGIN
        base_time := NOW() - interval '3 years';
        FOR ride_rec IN SELECT * FROM ride_info
            LOOP
                SELECT count_stations
                INTO total_stations
                FROM routes_info
                WHERE route_id = ride_rec.route_id;

                FOR direction_order IN 1..total_stations
                    LOOP
                        IF ride_rec.direction = 'обратное' THEN
                            station_counter := total_stations - direction_order + 1;
                        ELSE
                            station_counter := direction_order;
                        END IF;

                        -- Получаем данные станции
                        SELECT *
                        INTO route_rec
                        FROM routes
                        WHERE route_id = ride_rec.route_id
                          AND station_order = direction_order;
                        station_time := base_time + (direction_order * INTERVAL '30 minutes');

                        if (random() < 0.7) THEN
                            delay := 0;
                        else
                            delay := floor(random() * 20)::INT;
                        end if;
                        INSERT INTO timetable (ride_id,
                                               station_order,
                                               planned_arrival_time,
                                               planned_departure_time,
                                               actual_arrival_time, actual_departure_time)
                        VALUES (ride_rec.ride_id,
                                station_counter,
                                station_time,
                                station_time + INTERVAL '5 minutes',
                                station_time + (delay * INTERVAL '1 minute'),
                                station_time + INTERVAL '5 minutes' + (delay * INTERVAL '1 minute'));
                    END LOOP;

                base_time := base_time + INTERVAL '1 hour 30 minutes';
            END LOOP;
    END
$$;

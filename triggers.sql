-- 1. Написать триггер, проверяющий, корректные ли данные вносятся в timetable
-- в части соответствия поезда и станции назначенному на данный поезд маршруту.
CREATE OR REPLACE function check_new_station_in_timetable()
    returns trigger as
$$
DECLARE
    count_st int;
BEGIN
    select count_stations into count_st from routes_info;
    if (new.station_order > count_st or new.station_order < 0) then
        RAISE EXCEPTION 'этой станции нет в маршруте';
    end if;
    return new;
end;
$$ LANGUAGE plpgsql;

create trigger new_station_in_timetable
    before insert
    on timetable
    for each row
execute function check_new_station_in_timetable();

INSERT into timetable (ride_id, station_order, planned_arrival_time, planned_departure_time, actual_arrival_time,
                       actual_departure_time)
VALUES (1, 100, now(), now(), now(), now());

-- 2. Написать триггер, проверяющий, верно ли в таблице расписаний стоит время при внесении новых данных (новой строки):
-- оно должно быть больше времени, стоящего для предыдущей (в соответствии с маршрутом) станции данного поезда.
-- Если текущее время меньше предыдущего триггер должен автоматически сделать текущее время больше предыдущего на заданный интервал.
-- Интервал ищется триггером автоматически путём поиска онного у других поездов,
-- передвигающихся между этими же двумя точками. Если таковых нет, интервал берётся дефолтный (константа).
CREATE OR REPLACE FUNCTION check_route_in_timetable()
    RETURNS TRIGGER AS
$$
DECLARE
    prev_departure TIMESTAMP;
    avg_interval   INTERVAL := INTERVAL '10 minutes';
    route_id_new   INT;
BEGIN
    SELECT route_id
    into route_id_new
    FROM ride_info
    WHERE ride_id = new.ride_id;
    SELECT planned_departure_time
    into prev_departure
    FROM timetable
    WHERE ride_id = new.ride_id
      AND station_order = new.station_order - 1;


    if FOUND AND new.planned_arrival_time < prev_departure THEN
        raise notice 'некорректное время для станции % маршрута %', new.station_order, new.ride_id;

        SELECT avg(t1.planned_departure_time - t2.planned_arrival_time)
        into avg_interval
        FROM timetable t1
                 JOIN timetable t2 ON t1.ride_id = t2.ride_id
            AND t1.station_order = t2.station_order - 1
                 JOIN ride_info ri ON t1.ride_id = ri.ride_id
        WHERE ri.route_id = route_id_new
          AND t1.station_order = new.station_order - 1
          AND t2.station_order = new.station_order
          AND t1.ride_id != new.ride_id;
        raise notice '% ', avg_interval;
        if (avg_interval is)
            new.planned_arrival_time := prev_departure + avg_interval;

        if new.planned_departure_time < new.planned_arrival_time THEN
            new.planned_departure_time := new.planned_arrival_time + INTERVAL '3 minutes';
        END if;

        raise notice 'Новое время прибытия: %, отправления: %',
            new.planned_arrival_time,
            new.planned_departure_time;
    END if;

    return new;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER find_new_interval_between_stations
    BEFORE INSERT OR UPDATE
    ON timetable
    FOR EACH ROW
EXECUTE FUNCTION check_route_in_timetable();
-- 1,1,2022-04-01 13:36:23.639271,2022-04-01 13:41:23.639271,2022-04-01 13:43:23.639271
-- 1,2,2022-04-01 14:06:23.639271,2022-04-01 14:11:23.639271,2022-04-01 14:13:23.639271,2022-04-01 14:18:23.639271
UPDATE timetable
SET planned_arrival_time = '2022-04-01 12:15'
WHERE (station_order = 2 and ride_id = 1);



-- 3. Написать триггер для таблицы маршрутов, который автоматически ставит номер маршрута,
-- если онный не заполнен при вставке данных. Номер ставится по следующему правилу:
-- минимальное число, которого нет ни в таблице маршрутов, ни в таблице расписания.


create or replace function find_new_route_id()
    returns trigger as
$$
declare
    current_id int := 1;
    el         int;

begin
    if new.route_id is null then

        for el in (select route_id from routes_info UNION select route_id from ride_info order by route_id)
            loop
                if (current_id != el) then
                    new.route_id := current_id;
                    exit;
                end if;
                current_id := current_id + 1;

            end loop;

    end if;
    return new;
end;
$$ language plpgsql;

create trigger create_new_route_id
    before insert
    on routes_info
    for each row
execute function find_new_route_id();

select max(route_id)
from routes_info;
INSERT into routes_info(route_id, count_stations)
VALUES (5007, 50);

INSERT into routes_info(count_stations)
VALUES (20);

select *
from routes_info;



-- 4. Написать триггер, который логирует (записывает все параметры в отдельную таблицу учёта) все удаления поездов,
-- на которых было продано более 300 билетов. В таблицу аудита надо бы записать и число удалённых билетов
CREATE TABLE if not exists log_trains
(
    id                    SERIAL PRIMARY KEY,
    train_id              INT,
    train_number          varchar(50) not null,
    count_deleted_tickets INT,
    author                name,
    data_of_change        TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_deleted_trains()
    RETURNS TRIGGER AS
$$
DECLARE
    rec           record;
    count_tickets INT;
BEGIN


    SELECT count(*)
    into count_tickets
    from tickets
             JOIN ride_info ri on tickets.ride_id = ri.ride_id AND old.id = train_id
    WHERE train_id = old.id;
    SELECT * into rec FROM trains WHERE trains.id = old.id;
    if (count_tickets > 300) then
        insert into log_trains (train_id, train_number, count_deleted_tickets, author, data_of_change)
        values (old.id, rec.train_number, count_tickets, current_user, now());
    end if;
-- add user, data
    RETURN old;
end;
$$ LANGUAGE plpgsql;


create trigger log_deleted_trains
    before delete
    on trains
    for each row
execute function log_deleted_trains();


delete
from trains
where id = 10;

select *
from log_trains;
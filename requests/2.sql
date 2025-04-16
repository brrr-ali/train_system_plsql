DO
$$
    DECLARE
        sum_passengers  INT  := 0;
        sum_distances   INT  := 0;
        sum_rides       INT  := 0;
        start_date      DATE := '11.10.2022';
        current_quarter INT  := EXTRACT(QUARTER FROM start_date);
        current_year_   INT  := EXTRACT(YEAR FROM start_date);
        year_passengers INT  := 0;
        year_distances  INT  := 0;
        year_rides      INT  := 0;
        current_date_in DATE := start_date;
        today_rec       record;

    BEGIN
        drop table if exists distances;
        create temp table distances as (SELECT routes.station_order                                       AS station_order,
                                               routes.route_id,
                                               SUM(routes.distance)
                                               OVER (PARTITION BY routes.route_id ORDER BY station_order) AS sum_distance
                                        FROM routes);

        WHILE current_date_in <= current_date
            loop
                if (current_quarter != EXTRACT(QUARTER from current_date_in)) then
                    RAISE NOTICE '% | % | % | %',
                        RPAD('Q' || current_quarter::TEXT, 10),
                        LPAD(sum_passengers::TEXT, 10),
                        LPAD(sum_rides::TEXT, 15), LPAD(sum_distances::TEXT, 15);
                    if (current_year_ != extract(year from current_date_in)) then
                        RAISE NOTICE '% | % | % | %',
                            RPAD('Y' || current_year_::TEXT, 10),
                            LPAD(year_passengers::TEXT, 15),
                            LPAD(year_rides::TEXT, 10), LPAD(year_distances::TEXT, 15);
                        year_rides := 0;
                        year_passengers := 0;
                        year_distances := 0;
                        current_year_ := extract(year from current_date_in);
                    end if;
                    year_rides := year_rides + sum_rides;
                    year_passengers := year_passengers + sum_passengers;
                    year_distances := year_distances + sum_distances;
                    sum_rides := 0;
                    sum_passengers := 0;
                    sum_distances := 0;
                    current_quarter := EXTRACT(QUARTER from current_date_in);
                end if;
                SELECT count(distinct public.tickets.ride_id)               as count_rides,
                       count(tickets.id)                                    as count_passengers,
                       sum(end_dist.sum_distance - start_dist.sum_distance) AS distance
                into today_rec
                FROM tickets
                         JOIN ride_info ON tickets.ride_id = ride_info.ride_id
                         JOIN timetable
                              ON ride_info.ride_id = timetable.ride_id AND
                                 timetable.station_order = tickets.start_station_order
                         JOIN distances start_dist ON ride_info.route_id = start_dist.route_id
                    AND tickets.start_station_order = start_dist.station_order
                         JOIN distances end_dist ON ride_info.route_id = end_dist.route_id
                    AND tickets.end_station_order = end_dist.station_order
                WHERE (planned_arrival_time)::DATE = current_date_in;

                sum_passengers := sum_passengers + today_rec.count_passengers;
                sum_rides := sum_rides + today_rec.count_rides;
                sum_distances := sum_distances + today_rec.distance;
                raise NOTICE '% | % | % | %', LPAD(current_date_in::TEXT, 15), LPAD(sum_passengers::TEXT, 15),
                    LPAD(sum_rides::TEXT, 15), LPAD(sum_distances::TEXT, 15);
                current_date_in := current_date_in + INTERVAL '1 day';
            end loop;

        RAISE NOTICE '% | % | % | % ',
            RPAD('Q' || current_quarter::TEXT, 10),
            LPAD(sum_passengers::TEXT, 10),
            LPAD(sum_rides::TEXT, 15),
            LPAD(sum_distances::TEXT, 15);

        RAISE NOTICE '% | % | % | %',
            RPAD('Y' || current_year_::TEXT, 10),
            LPAD(year_passengers::TEXT, 15),
            LPAD(year_rides::TEXT, 10),
            LPAD(year_distances::TEXT, 15);
    EXCEPTION
        WHEN OTHERS THEN RAISE NOTICE 'Ошибка: %', SQLERRM;
    END
$$ LANGUAGE plpgsql;
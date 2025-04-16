CREATE OR REPLACE FUNCTION update_delayed_trains(p_date DATE)
    RETURNS VOID AS
$$
BEGIN
    UPDATE timetable
    SET planned_arrival_time   = actual_arrival_time,
        planned_departure_time = actual_departure_time
    FROM timetable WHERE (planned_arrival_time)::date = p_date
            AND actual_arrival_time <> planned_arrival_time;
    RAISE NOTICE 'Обновление завершено';
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Ошибка обновления: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;


select update_delayed_trains('2023-04-16');

WITH distances AS (SELECT routes.station_order                                       AS station_order,
                          routes.route_id,
                          SUM(routes.distance)
                          OVER (PARTITION BY routes.route_id ORDER BY station_order) AS sum_distance
                   FROM routes),

     reservation_info AS (SELECT tickets.ride_id,
                                 end_dist.sum_distance - start_dist.sum_distance AS distance,
                                 CAST(timetable.planned_arrival_time AS DATE)    as date_
                          FROM tickets
                                   JOIN ride_info ON tickets.ride_id = ride_info.ride_id
                                   JOIN timetable
                                        ON ride_info.ride_id = timetable.ride_id AND
                                           timetable.station_order = tickets.start_station_order
                                   JOIN distances start_dist ON ride_info.route_id = start_dist.route_id
                              AND tickets.start_station_order = start_dist.station_order
                                   JOIN distances end_dist ON ride_info.route_id = end_dist.route_id
                              AND tickets.end_station_order = end_dist.station_order),

     result_per_day as (SELECT date_,
                               extract('quarter' from date_) as quarter_,
                               extract('year' from date_)    as year_,
                               count(distinct ride_id)       as rides_per_day,
                               count(*)                      as passengers_per_day,
                               sum(distance)                 as kmiters_per_day
                        FROM reservation_info
                        group by date_),
     commulative_data as (SELECT date_,
                                 quarter_,
                                 year_,
                                 sum(rides_per_day)
                                 OVER (partition by (quarter_, year_) ORDER BY date_ ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as rides_o,
                                 sum(passengers_per_day)
                                 OVER (partition by (quarter_, year_) ORDER BY date_ ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as passengers_o,
                                 sum(kmiters_per_day)
                                 OVER (partition by (quarter_, year_) ORDER BY date_ ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as distance_o
                          FROM result_per_day
                          ORDER BY date_)

    (select null                    as date_,
            quarter_,
            year_,
            sum(rides_per_day)      as rides_o,
            sum(passengers_per_day) as passengers_o,
            sum(kmiters_per_day)    as distance_o
     from result_per_day
     group by rollup (year_, quarter_)
     ORDER by year_, quarter_)

UNION ALL
(select * from commulative_data)
;


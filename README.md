# train_system_plsql
Задание по курсу "Базы данных" в НГУ, заключалось в том, чтобы разработать систему хранения поездок железнодорожного транспорта и написать триггеры и запросы. Была перечисленна обязательная информация, которую нужно было сохранить. 

Для запуска бд, необходимо:
1) выполнить скрипт `create.sql`
2) заменить в `insert_trains\Main.java` переменные dbUrl, username, password. А затем исполнить этот файл. Так заполнится часть таблиц.
3) запустить скрипт `insert.sql`
Теперь база заполнена и готова к работе.

`diagram_trains.png` - ER-диаграмма разработанной бд. 

В `triggers.sql` перед каждым триггером написано за что он отвечает.

Запросы из `requests\1.sql`и `requests\2.sql` предназначены для формирования кумулятивного отчёта по датам, содержащего число перевезённых от даты начала отчёта до текущей даты пассажиров с подведением итогов по кварталам и по годам.

В `requests\3.sql` нужно было написать функцию, которая выбирает все поезда из расписания, которые задерживаются на заданную в аргументах функции дату, исправляет время прибытия по расписанию в соответствии с задержкой и обнуляет задержку.


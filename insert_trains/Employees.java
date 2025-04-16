package insert_trains;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class Employees extends BaseInsertClass {
    Employees(Connection connection) {
        super(connection);
    }

    int count = 5000;

    void beforeEmployeesInsert() throws SQLException {
        String insertPositionsSQL = "INSERT INTO positions (name) VALUES (?)";
        String[] positions = {
                "Машинист",
                "Помощник машиниста",
                "Начальник поезда",
                "Проводник",
                "Инженер",
                "Диспетчер",
                "Кассир",
                "Охранник",
                "Уборщик",
                "Техник"
        };
        PreparedStatement pstmt = connection.prepareStatement(insertPositionsSQL);
        for (String position : positions) {
            pstmt.setString(1, position);
            pstmt.addBatch();
        }
        pstmt.executeBatch();
        System.out.println("Должности сотрудников добавлены");

        String insertCrewsSQL = "INSERT INTO crews (head_station_id) SELECT id FROM stations ORDER BY RANDOM() LIMIT 100";
        PreparedStatement pstmt2 = connection.prepareStatement(insertCrewsSQL);
        pstmt2.executeUpdate();
        System.out.println("Бригады добавлены");
    }

    @Override
    void insert() throws SQLException {
        beforeEmployeesInsert();
        String insertSQL = "INSERT INTO employees (first_name, last_name, email, phone_number, position_id, manager_id, assigned_station_id, crew_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        List<Integer> employeeIds = new ArrayList<>();
        try {
            for (int i = 0; i < count; i++) {
                // Подготавливаем запрос с возвратом сгенерированных ключей
                PreparedStatement preparedStatement = connection.prepareStatement(insertSQL, PreparedStatement.RETURN_GENERATED_KEYS);

                // Заполняем параметры
                preparedStatement.setString(1, faker.name().firstName());
                preparedStatement.setString(2, faker.name().lastName());
                preparedStatement.setString(3, faker.internet().emailAddress());
                preparedStatement.setString(4, faker.phoneNumber().cellPhone());
                preparedStatement.setInt(5, faker.random().nextInt(1, 10));

                // Выбираем manager_id из существующих сотрудников, если они есть
                if (employeeIds.isEmpty()) {
                    preparedStatement.setNull(6, java.sql.Types.INTEGER);
                } else {
                    int managerIndex = faker.random().nextInt(employeeIds.size());
                    preparedStatement.setInt(6, employeeIds.get(managerIndex));
                }

                preparedStatement.setInt(7, faker.random().nextInt(1, 7000));
                preparedStatement.setInt(8, faker.random().nextInt(1, 100));

                // Выполняем вставку
                preparedStatement.executeUpdate();

                // Получаем сгенерированный ID
                try (ResultSet generatedKeys = preparedStatement.getGeneratedKeys()) {
                    if (generatedKeys.next()) {
                        int id = generatedKeys.getInt(1);
                        employeeIds.add(id);
                    } else {
                        throw new SQLException("Не удалось получить ID сотрудника.");
                    }
                }

                preparedStatement.close();
            }
            System.out.println("Сотрудники добавлены");
        } catch (SQLException e) {
            System.out.println("Ошибка: " + e.getMessage());
        }
    }
}
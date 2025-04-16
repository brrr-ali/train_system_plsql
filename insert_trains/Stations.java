package insert_trains;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class Stations extends BaseInsertClass {
    Stations(Connection connection) {
        super(connection);
        count = 7000;
    }

    @Override
    void insert() {
        String insertSQL = "INSERT INTO stations (station_name) VALUES (?)";
        try (PreparedStatement preparedStatement = connection.prepareStatement(insertSQL)) {
            for (int i = 1; i <= count; i++) {
                preparedStatement.setString(1, faker.address().city());
                preparedStatement.addBatch();
                if (i % 1000 == 0) {
                    preparedStatement.executeBatch();
                }           }
            preparedStatement.executeBatch();
            System.out.println("добавление stations прошло успешно");
        } catch (SQLException e) {
            System.out.println("Ошибка " + e.getMessage());
        }
    }
}

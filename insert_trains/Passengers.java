package insert_trains;

import org.json.JSONObject;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Types;

public class Passengers extends BaseInsertClass {
    Passengers(Connection connection) {
        super(connection);
        count = 75000;
    }

    @Override
    void insert() {
        String insertSQL = "INSERT INTO passengers (passport_info, email, phone_number) VALUES (?, ?, ?)";
        try (PreparedStatement preparedStatement = connection.prepareStatement(insertSQL)) {
            for (int i = 1; i <= count; i++) {
                JSONObject passportInfo = new JSONObject();
                passportInfo.put("fullName", faker.name().fullName());
                passportInfo.put("passport", faker.code().asin());
                preparedStatement.setObject(1, passportInfo.toString(), Types.OTHER);
                preparedStatement.setString(2, faker.internet().emailAddress());
                preparedStatement.setString(3, (faker.phoneNumber().cellPhone()));
                preparedStatement.addBatch();
                if (i % 1000 == 0) {
                    preparedStatement.executeBatch();
                }
            }
            preparedStatement.executeBatch();
            System.out.println("добавление пассажиров прошло успешно");
        } catch (SQLException e) {
            System.out.println("Ошибка " + e.getMessage());
        }
    }
}

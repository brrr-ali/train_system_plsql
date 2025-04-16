package insert_trains;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class Main {
    public static void main(String[] args) {
        String dbUrl = "jdbc:postgresql://localhost:PORT/NAMEDATABASE";
        String username = "INSERT YOUR USERNAME";
        String password = "INSERT YOUR PASSWORD";
        try (Connection connection = DriverManager.getConnection(dbUrl, username, password)) {
            if (connection != null) {
                System.out.println("Успех");
            } else {
                System.out.println("Не удалось подключиться");
            }

            new Passengers(connection).insert();
            new Stations(connection).insert();
            new Employees(connection).insert();
        } catch (SQLException e) {
            System.out.println("Ошибка при подключении к базе данных: " + e.getMessage());
            e.printStackTrace();
        }
    }

}

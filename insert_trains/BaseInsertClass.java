package insert_trains;

import com.github.javafaker.Faker;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;

public abstract class BaseInsertClass {
    Connection connection;
    static Faker faker = new Faker();
    int count = 0;

    abstract void insert() throws SQLException;

    BaseInsertClass(Connection connection) {
        this.connection = connection;
    }

    int getMaxIdFromTable(String tableName) throws SQLException {
        String selectMaxLoan = "SELECT max(id) as m FROM " + tableName;
        ResultSet rs = connection.prepareStatement(selectMaxLoan).executeQuery();
        int n = 0;
        if (rs.next()) {
            n = rs.getInt("m");
            System.out.println(n);
        } else {
            System.out.println("No data found.");
        }
        return n;
    }
}

#include "DatabaseAPI.mqh"

class QueryBuilder
{
private:
    string table;             // Таблица
    string columns;           // Столбцы для выборки
    string conditions;        // Условия WHERE
    string ordering;          // Условия ORDER BY
    string values;            // Значения для INSERT
    string joins;             // JOIN-условия
    string queryType;         // Тип запроса: SELECT, INSERT и т.д.

public:
    // Constructor
    QueryBuilder()
    {
        reset();
    }

    // Сброс параметров для нового запроса
    void reset()
    {
        table = "";
        columns = "*";
        conditions = "";
        ordering = "";
        values = "";
        joins = "";
        queryType = "SELECT";
    }

    // Метод выбора столбцов
    void select(string cols = "*")
    {
        queryType = "SELECT";
        columns = cols;
    }

    // Метод для указания таблицы
    void From(string tbl)
    {
        table = tbl;
    }

    // Метод для добавления условий WHERE
    void where(string column, string op, string value)
    {
        if (conditions != "")
            conditions += " AND ";
        conditions += column + " " + op + " '" + value + "'";
    }

    // Метод для сортировки
    void orderBy(string column, string direction = "ASC")
    {
        ordering = " ORDER BY " + column + " " + direction;
    }

    // Метод для добавления JOIN
    void join(string joinTable, string condition, string type = "INNER")
    {
        joins += " " + type + " JOIN " + joinTable + " ON " + condition;
    }

    // Метод для добавления INSERT
    void insert(string tbl, string cols, string vals)
    {
        queryType = "INSERT";
        table = tbl;
        columns = "(" + cols + ")";
        values = "VALUES (" + vals + ")";
    }

    // Метод выполнения запроса с автоматическим подключением
    void get()
    {
        // Automatically handle database connection and disconnection
        if (DatabaseAPI::isConnected == false)
        {
            DatabaseAPI::connect();
        }

        string query = "SELECT " + columns + " FROM " + table;
        if (conditions != "")
            query += " WHERE " + conditions;
        if (ordering != "")
            query += ordering;

        // Execute query and retrieve results
        Print("Executing query: " + query);
        DatabaseAPI::execute(query);

        // Optional: Automatically disconnect after execution
        DatabaseAPI::disconnect();
    }
};

#include "DatabaseAPI.mqh"

class QueryBuilder
{
private:
    string table;             // Table
    string columns;           // Columns for selection
    string conditions;        // WHERE conditions
    string ordering;          // ORDER BY conditions
    string values;            // Values for INSERT
    string joins;             // JOIN conditions
    string queryType;         // Query type: SELECT, INSERT, etc.

public:
    // Constructor
    QueryBuilder()
    {
        reset();
    }

    // Reset parameters for a new query
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

    // Method to select columns
    void select(string cols = "*")
    {
        queryType = "SELECT";
        columns = cols;
    }

    // Method to specify the table
    void From(string tbl)
    {
        table = tbl;
    }

    // Method to add WHERE conditions
    void where(string column, string op, string value)
    {
        if (conditions != "")
            conditions += " AND ";
        conditions += column + " " + op + " '" + value + "'";
    }

    // Method for sorting
    void orderBy(string column, string direction = "ASC")
    {
        ordering = " ORDER BY " + column + " " + direction;
    }

    // Method to add JOIN
    void join(string joinTable, string condition, string type = "INNER")
    {
        joins += " " + type + " JOIN " + joinTable + " ON " + condition;
    }

    // Method to add INSERT
    void insert(string tbl, string cols, string vals)
    {
        queryType = "INSERT";
        table = tbl;
        columns = "(" + cols + ")";
        values = "VALUES (" + vals + ")";
    }

    // Method to execute the query with automatic connection
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

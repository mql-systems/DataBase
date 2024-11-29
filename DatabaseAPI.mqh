namespace DatabaseAPI
{
    // Store connection handle globally
    int handle = -1;
    bool isConnected = false;

    // Connect to the database
    void connect()
    {
        if (isConnected)
            return;

        handle = DatabaseOpen("db.db", DATABASE_OPEN_READWRITE|DATABASE_OPEN_CREATE);
        if (handle == -1)
        {
            Print("Database connection failed!");
            return;
        }
        isConnected = true;
        Print("Database connected.");
    }

    // Disconnect from the database
    void disconnect()
    {
        if (isConnected)
        {
            DatabaseClose(handle);
            isConnected = false;
            Print("Database disconnected.");
        }
    }

    // Execute a query
    void execute(string query)
    {
        if (handle == -1)
        {
            Print("No active database connection.");
            return;
        }

        if (!DatabaseExecute(handle, query))
        {
            Print("Query execution failed: " + query);
        }
        else
        {
            Print("Query executed successfully.");
        }
    }
}

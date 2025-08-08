# MQL5 Fluent Query Builder

![MQL5](https://img.shields.io/badge/MQL5-Ready-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

An elegant and powerful fluent SQL query builder for the MQL5 language. Stop manually concatenating messy SQL strings and start building queries with an intuitive, object-oriented interface. This library provides a seamless way to interact with SQLite databases directly from your EAs, indicators, and scripts.

## 🌟 Key Features

* **Fluent Interface:** Chain methods together to construct complex queries in a clean, readable way.
* **Safe & Convenient:** Automatically handles the formatting of string and numeric values.
* **Driver-Based Architecture:** Built with a flexible driver system, featuring out-of-the-box support for SQLite.
* **Full CRUD Support:** All common operations are supported: `SELECT`, `INSERT`, `UPDATE`, `DELETE`.
* **Advanced Queries:** Easily perform `JOINs`, `GROUP BY` clauses, aggregate functions, and more.
* **Robust Error Handling:** A built-in status system lets you check the result of every query.
* **Unit Tested:** The library is fully covered by unit tests to ensure reliability and stability.

---

## 💾 Installation

1.  Download the library archive.
2.  Unpack it and copy the `Database` folder into your terminal's `MQL5/Include/` directory.
3.  Your final file structure should look like this:
    ```
    MQL5/
    └── Include/
        └── Database/
            ├── Drivers/
            │   ├── IDatabaseDriver.mqh
            │   └── SQLiteDriver.mqh
            ├── Common/
            │   └── Enums.mqh
            ├── QueryBuilder.mqh
            ├── DatabaseManager.mqh
            └── Database.mqh
    ```
4.  To use the library in your project (EA, script, etc.), simply add this single line:
    ```mql5
    #include <Database/Database.mqh>
    ```

---

## 🚀 Quick Start

This example demonstrates the basic workflow of the library.

```mql5
#include <Database/Database.mqh>

DatabaseManager dbManager;

void OnStart()
{
    // 1. Connect to the database (the file will be created in MQL5/Files/)
    if (!dbManager.Open("my_signals.sqlite", DB_SQLITE))
    {
        Print("Failed to open DB: ", dbManager.GetLastError());
        return;
    }

    // 2. Create a table if it doesn't exist
    dbManager.CreateTable("signals", "id INTEGER PRIMARY KEY, symbol TEXT, price REAL, time DATETIME");

    // 3. Get the Query Builder instance
    QueryBuilder* qb = dbManager.Query();
    if (qb == NULL) return;

    // 4. Insert a new record
    string cols[] = {"symbol", "price", "time"};
    string vals[] = {"EURUSD", "1.0755", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES)};
    qb->Table("signals")->Insert(cols, vals);

    // 5. Get the total count of signals for EURUSD
    long count = qb->Table("signals")->Where("symbol", "EURUSD")->Count();
    PrintFormat("Found %d signals for EURUSD", count);

    // 6. Get the most recent record
    int request = qb->Table("signals")->OrderBy("time", "DESC")->First();
    if (request != INVALID_HANDLE)
    {
        if (DatabaseRead(request))
        {
            string symbol;
            double price;
            DatabaseColumnString(request, 1, symbol);
            DatabaseColumnDouble(request, 2, price);
            PrintFormat("Last signal: %s at price %f", symbol, price);
        }
        DatabaseFinalize(request);
    }
    
    // 7. Free the memory
    delete qb;
    
    // 8. Close the connection (optional, will be closed automatically on deinitialization)
    dbManager.Close();
}
````

-----

## 📖 Usage Guide

### Connection

```mql5
#include <Database/Database.mqh>

DatabaseManager dbManager;

// Connect in OnStart or OnInit
dbManager.Open("filename.sqlite", DB_SQLITE);

// Close in OnDeinit
dbManager.Close();
```

### Retrieving Data (SELECT)

#### Get All Records

```mql5
QueryBuilder* qb = dbManager.Query();
int request = qb->Table("users")->Get();
// ... loop through results with DatabaseRead() ...
DatabaseFinalize(request);
```

#### Get a Single Record (`First`)

```mql5
int request = qb->Table("users")->Where("id", 1)->First();
// ... read the single row ...
```

#### Select Specific Columns (`Select`)

```mql5
int request = qb->Table("users")->Select("name, email")->Get();
```

#### Aggregates (`Count`, `Exists`)

```mql5
long userCount = qb->Table("users")->Where("active", 1)->Count();
Print("Active users: ", userCount);

if (qb->Table("users")->Where("name", "John")->Exists())
{
    Print("User John exists!");
}
```

### WHERE Clauses

The library supports a full range of `WHERE` conditions.

```mql5
// Simple WHERE
qb->Table("users")->Where("votes", ">", 100);

// Chained AND WHERE
qb->Table("users")->Where("votes", ">", 100)->Where("age", ">", 30);

// OR WHERE
qb->Table("users")->Where("votes", ">", 100)->OrWhere("name", "Admin");

// WhereIn: value is in an array
string names[] = {"John", "Jane"};
qb->Table("users")->WhereIn("name", names);

// WhereBetween: value is in a range
qb->Table("users")->WhereBetween("age", 20, 30);

// WhereNull / WhereNotNull: check for NULL values
qb->Table("users")->WhereNull("last_login_date");
```

### Ordering, Grouping & Limiting

```mql5
// Ordering
qb->Table("users")->OrderBy("name", "ASC");
qb->Table("users")->OrderByDesc("age");

// Grouping
qb->Table("orders")->Select("user_id, COUNT(id) as order_count")->GroupBy("user_id");

// Limit (LIMIT)
qb->Table("posts")->Limit(10); // Get 10 records
```

### JOINs

```mql5
// INNER JOIN
qb->Table("users")
  ->Join("orders", "users.id", "=", "orders.user_id")
  ->Select("users.name, orders.item");

// LEFT JOIN
qb->Table("users")
  ->LeftJoin("profiles", "users.id", "=", "profiles.user_id");
```

### Inserting Data (INSERT)

```mql5
string cols[] = {"name", "email", "age"};
string vals[] = {"Sarah", "sarah@example.com", "28"};

bool result = qb->Table("users")->Insert(cols, vals);
if (result)
{
    Print("User added successfully!");
}
```

To insert a `NULL` value, use the string `"NULL"`:

```mql5
string vals[] = {"Peter", "peter@example.com", "NULL"};
qb->Table("users")->Insert(cols, vals);
```

### Updating Data (UPDATE)

**Important:** For safety, the `Update` method requires a `Where` clause.

```mql5
string cols[] = {"age"};
string vals[] = {"29"};

qb->Table("users")->Where("name", "Sarah")->Update(cols, vals);
```

### Deleting Data (DELETE)

**Important:** For safety, the `Delete` method also requires a `Where` clause.

```mql5
qb->Table("users")->Where("age", "<", 18)->Delete();

// To delete all records from a table, use the dedicated method
qb->Table("users")->DeleteAll();
```

### Error Handling

After every "terminating" call (`Get`, `Count`, `Insert`, etc.), you can check the status of the operation.

```mql5
long count = qb->Table("non_existent_table")->Count();

if (qb->GetLastStatus() != QUERY_OK)
{
    Print("An error occurred: ", qb->GetLastError());
    // Output: An error occurred: no such table: non_existent_table
}
```

-----

## 🧪 Testing

To verify the library is working correctly, you can run the provided unit tests.

1.  Place the `TestQueryBuilder.mq5` file into your `MQL5/Scripts/Tests/` folder.
2.  Compile it in MetaEditor.
3.  Drag the script onto any chart in your terminal.
4.  The test results will be printed in the "Experts" tab.

-----

## 📜 License

This library is open-source software licensed under the [MIT license](https://opensource.org/licenses/MIT).
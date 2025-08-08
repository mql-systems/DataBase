#include <MqlSystems/DB/Database.mqh>

//--- Global variables
DatabaseManager dbManager;
const string TEST_DB_FILENAME = "unit_test_dbqb.sqlite";
int g_tests_passed = 0;
int g_tests_failed = 0;

//+------------------------------------------------------------------+
//| Assertion helper functions                                       |
//+------------------------------------------------------------------+
void AssertTrue(bool condition, string message)
{
   if (condition)
   {
      PrintFormat("  ✅ PASS: %s", message);
      g_tests_passed++;
   }
   else
   {
      PrintFormat("  ❌ FAIL: %s", message);
      g_tests_failed++;
   }
}

void AssertEquals(long actual, long expected, string message)
{
   AssertTrue(actual == expected, message + " [Expected: " + (string)expected + ", Actual: " + (string)actual + "]");
}

void AssertString(string actual, string expected, string message)
{
   AssertTrue(actual == expected, message + " [Expected: '" + expected + "', Actual: '" + actual + "']");
}

//+------------------------------------------------------------------+
//| Test environment setup and teardown (Setup & Teardown)           |
//+------------------------------------------------------------------+
bool Setup()
{
   Print("--- Setting up test environment ---");

   // Delete the old DB file if it exists
   dbManager.Close();
   if (FileIsExist(TEST_DB_FILENAME))
      FileDelete(TEST_DB_FILENAME);

   // Open the connection
   if (!dbManager.Open(TEST_DB_FILENAME, DB_SQLITE))
   {
      PrintFormat("CRITICAL: Failed to open test database at '%s'. Tests aborted.", TEST_DB_FILENAME);
      return false;
   }

   // Create and populate tables
   dbManager.CreateTable("users", "id INTEGER PRIMARY KEY, name TEXT, age INTEGER, country TEXT");
   dbManager.CreateTable("orders", "id INTEGER PRIMARY KEY, user_id INTEGER, item TEXT, amount REAL");

   string u_cols[] = {"id", "name", "age", "country"};
   string u_vals1[] = {"1", "John Doe", "30", "USA"};
   string u_vals2[] = {"2", "Jane Smith", "25", "Canada"};
   string u_vals3[] = {"3", "Peter Jones", "45", "UK"};
   string u_vals4[] = {"4", "No Country Man", "50", "NULL"};

   QueryBuilder *qb = dbManager.Query();
   if (qb == NULL)
      return false;

   qb.Table("users").Insert(u_cols, u_vals1);
   qb.Table("users").Insert(u_cols, u_vals2);
   qb.Table("users").Insert(u_cols, u_vals3);
   qb.Table("users").Insert(u_cols, u_vals4);

   string o_cols[] = {"id", "user_id", "item", "amount"};
   string o_vals1[] = {"101", "1", "Book", "19.99"};
   string o_vals2[] = {"102", "2", "Pen", "1.50"};
   string o_vals3[] = {"103", "1", "Notebook", "5.0"};
   qb.Table("orders").Insert(o_cols, o_vals1);
   qb.Table("orders").Insert(o_cols, o_vals2);
   qb.Table("orders").Insert(o_cols, o_vals3);
   delete qb;

   Print("--- Setup complete ---");
   return true;
}

void Teardown()
{
   Print("--- Tearing down test environment ---");
   dbManager.Close();
   if (FileIsExist(TEST_DB_FILENAME))
   {
      FileDelete(TEST_DB_FILENAME);
      Print("Test database file deleted.");
   }
   Print("--- Teardown complete ---");
}

void Test_SelectAndCount()
{
   Print("--- Testing: Select and Count ---");
   QueryBuilder *qb = dbManager.Query();

   long count = qb.Table("users").Count();
   AssertEquals(count, 4, "Count all users");

   count = qb.Table("users").Where("age", ">", "40").Count();
   AssertEquals(count, 2, "Count users with age > 40");

   delete qb;
}

void Test_WhereClauses()
{
   Print("--- Testing: WHERE clauses ---");
   QueryBuilder *qb = dbManager.Query();

   long count = qb.Table("users").Where("country", "USA").Count();
   AssertEquals(count, 1, "Simple WHERE");

   count = qb.Table("users").Where("age", ">", "28").Where("country", "UK").Count();
   AssertEquals(count, 1, "Chained AND WHERE");

   count = qb.Table("users").Where("country", "USA").OrWhere("country", "Canada").Count();
   AssertEquals(count, 2, "OR WHERE");

   string countries[] = {"USA", "UK"};
   count = qb.Table("users").WhereIn("country", countries).Count();
   AssertEquals(count, 2, "WHERE IN");

   count = qb.Table("users").WhereBetween("age", "20", "35").Count();
   AssertEquals(count, 2, "WHERE BETWEEN");

   count = qb.Table("users").WhereNull("country").Count();
   AssertEquals(count, 1, "WHERE NULL");

   count = qb.Table("users").WhereNotNull("country").Count();
   AssertEquals(count, 3, "WHERE NOT NULL");

   delete qb;
}

void Test_FirstAndOrder()
{
   Print("--- Testing: First, OrderBy, Limit ---");
   QueryBuilder *qb = dbManager.Query();

   int request = qb.Table("users").OrderBy("age", "DESC").First();
   AssertTrue(request != INVALID_HANDLE, "First() returns valid handle");

   if (request != INVALID_HANDLE)
   {
      string name;
      if (DatabaseRead(request) && DatabaseColumnText(request, 1, name))
         AssertString(name, "No Country Man", "First() with OrderBy gets the oldest user");
      else
         AssertTrue(false, "Failed to read data from First()");
      DatabaseFinalize(request);
   }

   delete qb;
}

void Test_Insert()
{
   Print("--- Testing: Insert ---");
   QueryBuilder *qb = dbManager.Query();

   string cols[] = {"id", "name", "age", "country"};
   string vals[] = {"5", "Test User", "99", "AU"};

   bool result = qb.Table("users").Insert(cols, vals);
   AssertTrue(result, "Insert() returns true on success");

   long count = qb.Table("users").Where("name", "Test User").Count();
   AssertEquals(count, 1, "Record exists after insert");

   delete qb;
}

void Test_Update()
{
   Print("--- Testing: Update ---");
   QueryBuilder *qb = dbManager.Query();

   string cols[] = {"age", "country"};
   string vals[] = {"31", "Australia"};

   bool result = qb.Table("users").Where("name", "John Doe").Update(cols, vals);
   AssertTrue(result, "Update() returns true on success");

   int request = qb.Table("users").Where("id", "1").First();
   if (request != INVALID_HANDLE)
   {
      long age;
      if (DatabaseRead(request) && DatabaseColumnLong(request, 2, age))
         AssertEquals(age, 31, "Record updated correctly");
      
      DatabaseFinalize(request);
   }

   delete qb;
}

void Test_Delete()
{
   Print("--- Testing: Delete ---");
   QueryBuilder *qb = dbManager.Query();

   bool result = qb.Table("users").Where("name", "Peter Jones").Delete();
   AssertTrue(result, "Delete() returns true on success");

   bool exists = qb.Table("users").Where("name", "Peter Jones").Exists();
   AssertTrue(!exists, "Record does not exist after delete");

   delete qb;
}

void Test_Join()
{
   Print("--- Testing: Join ---");
   QueryBuilder *qb = dbManager.Query();

   // Count the number of orders made by the user with the name "John Doe"
   long count = qb.Table("orders")
                  .Join("users", "orders.user_id", "=", "users.id")
                  .Where("users.name", "John Doe")
                  .Count();

   AssertEquals(count, 2, "JOIN correctly counts related records");

   delete qb;
}

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("===== RUNNING QueryBuilder UNIT TESTS =====");

   if (Setup())
   {
      Print("\n--- Running Test Cases ---");
      Test_SelectAndCount();
      Test_WhereClauses();
      Test_FirstAndOrder();
      Test_Insert();
      Test_Update();
      Test_Delete();
      Test_Join();
      Print("--- Test Cases Finished ---\n");
   }
   else
   {
      g_tests_failed++;
      Print("CRITICAL FAILURE: Test environment setup failed. No tests were run.");
   }

   Teardown();

   Print("===== TEST SUMMARY =====");
   PrintFormat("PASSED: %d, FAILED: %d", g_tests_passed, g_tests_failed);
   Print("========================");
}

//+------------------------------------------------------------------+
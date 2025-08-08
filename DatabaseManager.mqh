#include "Common/Enums.mqh"
#include "Drivers/MySQLDriver.mqh"
#include "Drivers/PostgreSQLDriver.mqh"
#include "Drivers/SQLiteDriver.mqh"
#include "QueryBuilder.mqh"

//+------------------------------------------------------------------+
//| DatabaseManager class                                            |
//+------------------------------------------------------------------+
class DatabaseManager
{
 private:
   IDatabaseDriver *m_driver;
   ENUM_DATABASE_TYPE m_dbType;
   bool m_logEnabled;
   string m_lastError;

   void Log(string message, string value = "")
   {
      if (m_logEnabled)
      {
         if (value != "")
            Print(message, " ", value);
         else
            Print(message);
      }
   }

 public:
   DatabaseManager() : m_driver(NULL), m_logEnabled(true)
   {
   }

   ~DatabaseManager()
   {
      Close();
   }

   //+------------------------------------------------------------------+
   //| Open database connection                                         |
   //+------------------------------------------------------------------+
   bool Open(string connection, ENUM_DATABASE_TYPE dbType = DB_SQLITE, uint flags = DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE)
   {
      if (m_driver != NULL)
         Close();

      m_dbType = dbType;
      switch (m_dbType)
      {
      case DB_SQLITE:
         m_driver = new SQLiteDriver();
         break;
      case DB_POSTGRESQL:
         m_driver = new PostgreSQLDriver();
         break;
      case DB_MYSQL:
         m_driver = new MySQLDriver();
         break;
      default:
         m_lastError = "Unsupported database type.";
         Log(m_lastError);
         return false;
      }

      if (m_driver.Open(connection, flags) == INVALID_HANDLE)
      {
         m_lastError = m_driver.GetLastErrorMsg();
         Log(m_lastError);
         delete m_driver;
         m_driver = NULL;
         return false;
      }

      Log("Database opened successfully:", connection);
      return true;
   }

   void Close()
   {
      if (m_driver != NULL)
      {
         m_driver.Close();
         delete m_driver;
         m_driver = NULL;
         Log("Database closed.");
      }
   }

   void SetLogging(bool enable)
   {
      m_logEnabled = enable;
   }

   QueryBuilder *Query()
   {
      if (m_driver == NULL)
      {
         m_lastError = "Error: Database not connected. Cannot create QueryBuilder instance.";
         Log(m_lastError);
         return NULL;
      }
      QueryBuilder *qb = new QueryBuilder(m_driver);
      qb.SetLogging(m_logEnabled);
      return qb;
   }

   //+------------------------------------------------------------------+
   //| Execute raw SQL                                                  |
   //+------------------------------------------------------------------+
   bool Execute(string query)
   {
      if (m_driver == NULL)
      {
         m_lastError = "Error: Database not connected.";
         Log(m_lastError);
         return false;
      }

      Log("Executing raw query:", query);
      if (!m_driver.Execute(query))
      {
         m_lastError = m_driver.GetLastErrorMsg();
         Log(m_lastError);
         return false;
      }
      return true;
   }

   //+------------------------------------------------------------------+
   //| Create table helper                                              |
   //+------------------------------------------------------------------+
   bool CreateTable(string tableName, string columns)
   {
      string query = "CREATE TABLE IF NOT EXISTS " + tableName + " (" + columns + ")";
      return Execute(query);
   }

   //+------------------------------------------------------------------+
   //| Drop table helper                                                |
   //+------------------------------------------------------------------+
   bool DropTable(string tableName)
   {
      string query = "DROP TABLE IF EXISTS " + tableName;
      return Execute(query);
   }

   string GetLastError() const
   {
      return m_lastError;
   }
};
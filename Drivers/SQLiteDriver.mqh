#include "IDatabaseDriver.mqh"

//+------------------------------------------------------------------+
//| Driver for SQLite                                                |
//+------------------------------------------------------------------+
class SQLiteDriver : public IDatabaseDriver
{
 private:
   int m_database;
   string m_lastError;

 public:
   SQLiteDriver() : m_database(INVALID_HANDLE)
   {
   }

   virtual int Open(string filename, uint flags) override
   {
      m_database = DatabaseOpen(filename, flags);
      if (m_database == INVALID_HANDLE)
         m_lastError = "Failed to open SQLite database. Error: " + IntegerToString(GetLastError());
         
      return m_database;
   }

   virtual void Close() override
   {
      if (m_database != INVALID_HANDLE)
      {
         DatabaseClose(m_database);
         m_database = INVALID_HANDLE;
      }
   }

   virtual bool Execute(string query) override
   {
      if (m_database == INVALID_HANDLE)
      {
         m_lastError = "SQLite database not connected.";
         return false;
      }
      if (!DatabaseExecute(m_database, query))
      {
         m_lastError = "Query execution failed. Error: " + IntegerToString(GetLastError());
         return false;
      }
      return true;
   }

   virtual int Prepare(string query) override
   {
      if (m_database == INVALID_HANDLE)
      {
         m_lastError = "SQLite database not connected.";
         return INVALID_HANDLE;
      }

      int request = DatabasePrepare(m_database, query);
      if (request == INVALID_HANDLE)
      {
         m_lastError = "DatabasePrepare failed. Error: " + IntegerToString(GetLastError());
      }
      return request;
   }

   virtual bool Read(int request) override
   {
      return DatabaseRead(request);
   }

   virtual bool ColumnLong(int request, int column, long &value) override
   {
      return DatabaseColumnLong(request, column, value);
   }

   virtual void Finalize(int request) override
   {
      DatabaseFinalize(request);
   }

   virtual string GetLastErrorMsg() override
   {
      return m_lastError;
   }

   virtual int GetHandle() override
   {
      return m_database;
   }
};

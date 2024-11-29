#include "DatabaseDriver.mqh"

// SQLite database driver
class SQLiteDriver : public DatabaseDriver {
private:
   int db; // Handle to the SQLite database connection

public:
   bool connect(const string& connectionString) override {
      // Open a database connection using DatabaseOpen
      db = DatabaseOpen(connectionString, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
      if (db == INVALID_HANDLE) {
         Print("Can't open database: ", GetLastError());
         return false;
      }
      return true;
   }

   bool query(const string& query) override {
      // Execute an SQL query using DatabaseExecute
      if (!DatabaseExecute(db, query)) {
         Print("DatabaseExecute error ", GetLastError());
         ResetLastError();
         return false;
      }

      return true;
   }

   int getAffectedRows() override
   {
      return 0; // TODO: Implement this method
   }

   int getLastInsertId() override
   {
      return 0; // TODO: Implement this method
   }
};

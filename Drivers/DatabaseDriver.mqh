class DatabaseDriver {
public:
   virtual bool connect(const string& connectionString) = 0;
   virtual bool query(const string& query) = 0;
   virtual int getAffectedRows() = 0;
   virtual int getLastInsertId() = 0;
};
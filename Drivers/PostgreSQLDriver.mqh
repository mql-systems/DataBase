#include "IDatabaseDriver.mqh"

//+------------------------------------------------------------------+
//| Stub driver for PostgreSQL                                       |
//+------------------------------------------------------------------+
class PostgreSQLDriver : public IDatabaseDriver
{
 private:
    string m_lastError;
    void SetNotImplementedError() { m_lastError = "PostgreSQL driver is not implemented."; Print(m_lastError); }

 public:
    virtual int Open(string connectionString, uint flags) override { SetNotImplementedError(); return INVALID_HANDLE; }
    virtual void Close() override {}
    virtual bool Execute(string query) override { SetNotImplementedError(); return false; }
    virtual int Prepare(string query) override { SetNotImplementedError(); return INVALID_HANDLE; }
    virtual bool Read(int request) override { return false; }
    virtual bool ColumnLong(int request, int column, long &value) override { return false; }
    virtual void Finalize(int request) override {}
    virtual string GetLastErrorMsg() override { return m_lastError; }
    virtual int GetHandle() override { return INVALID_HANDLE; }
};

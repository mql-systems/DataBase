//+------------------------------------------------------------------+
//| IDatabaseDriver interface                                        |
//+------------------------------------------------------------------+
class IDatabaseDriver
{
 public:
    virtual int      Open(string connectionString, uint flags) = 0;
    virtual void     Close() = 0;
    virtual bool     Execute(string query) = 0;
    virtual int      Prepare(string query) = 0;
    virtual bool     Read(int request) = 0;
    virtual bool     ColumnLong(int request, int column, long &value) = 0;
    virtual void     Finalize(int request) = 0;
    virtual string   GetLastErrorMsg() = 0;
    virtual int      GetHandle() = 0;
};
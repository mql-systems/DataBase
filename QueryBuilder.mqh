#include "Common/Enums.mqh"
#include "Drivers/IDatabaseDriver.mqh"

//+------------------------------------------------------------------+
//| QueryBuilder class                                               |
//+------------------------------------------------------------------+
class QueryBuilder
{
 private:
   IDatabaseDriver *m_driver;
   string m_table;
   string m_selectFields;
   string m_whereClause;
   string m_orderClause;
   string m_limitClause;
   string m_joinClause;
   string m_groupClause;
   string m_havingClause;
   bool m_logEnabled;
   ENUM_QUERY_STATUS m_lastStatus;
   string m_lastErrorMsg;

   //+------------------------------------------------------------------+
   //| Internal method for logging                                      |
   //+------------------------------------------------------------------+
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

   //+------------------------------------------------------------------+
   //| Check DB connection                                              |
   //+------------------------------------------------------------------+
   bool IsConnected()
   {
      if (m_driver == NULL || m_driver.GetHandle() == INVALID_HANDLE)
      {
         m_lastStatus = QUERY_ERROR_CONNECTION;
         m_lastErrorMsg = "Error: Database not connected";
         Log(m_lastErrorMsg);
         return false;
      }
      
      m_lastStatus = QUERY_OK;
      m_lastErrorMsg = "";
      return true;
   }

   //+------------------------------------------------------------------+
   //| Clearing the constructor state (for a new request)               |
   //+------------------------------------------------------------------+
   void ClearQueryState()
   {
      m_selectFields = "*";
      m_whereClause = "";
      m_orderClause = "";
      m_limitClause = "";
      m_joinClause = "";
      m_groupClause = "";
      m_havingClause = "";
   }
   
   //+------------------------------------------------------------------+
   //| Build SELECT query                                               |
   //+------------------------------------------------------------------+
   string BuildSelectQuery(bool for_count = false)
   {
      if (m_table == "")
      {
         m_lastStatus = QUERY_ERROR_NO_TABLE;
         m_lastErrorMsg = "Error: Table not specified";
         Log(m_lastErrorMsg);
         return "";
      }

      string query = "SELECT " + (for_count ? "COUNT(*)" : m_selectFields) + " FROM " + m_table;
      if (m_joinClause != "")
         query += " " + m_joinClause;
      if (m_whereClause != "")
         query += " " + m_whereClause;
      if (m_groupClause != "")
         query += " " + m_groupClause;
      if (m_havingClause != "")
         query += " " + m_havingClause;

      if (!for_count)
      {
         if (m_orderClause != "")
            query += " " + m_orderClause;
         if (m_limitClause != "")
            query += " " + m_limitClause;
      }

      return query;
   }

   string BuildInsertQuery(string &columns[], string &values[])
   {
      if (ArraySize(columns) != ArraySize(values) || ArraySize(columns) == 0)
      {
         m_lastStatus = QUERY_ERROR_INVALID_ARGUMENTS;
         m_lastErrorMsg = "Error: Columns and values arrays size mismatch or empty.";
         Log(m_lastErrorMsg);
         return "";
      }

      string columnStr = "";
      for (int i = 0; i < ArraySize(columns); i++)
         columnStr += (i == 0 ? "" : ", ") + columns[i];

      string valueStr = "";
      for (int i = 0; i < ArraySize(values); i++)
      {
         if (i > 0)
            valueStr += ", ";
         if (values[i] == "NULL")
            valueStr += "NULL";
         else
            valueStr += "'" + values[i] + "'";
      }

      return "INSERT INTO " + m_table + " (" + columnStr + ") VALUES (" + valueStr + ")";
   }

   string BuildUpdateQuery(string &columns[], string &values[])
   {
      if (ArraySize(columns) != ArraySize(values) || ArraySize(columns) == 0)
      {
         m_lastStatus = QUERY_ERROR_INVALID_ARGUMENTS;
         m_lastErrorMsg = "Error: Columns and values arrays size mismatch or empty.";
         Log(m_lastErrorMsg);
         return "";
      }

      if (m_whereClause == "")
      {
         m_lastStatus = QUERY_ERROR_EXECUTION;
         m_lastErrorMsg = "Warning: UPDATE without WHERE clause is not allowed for safety.";
         Log(m_lastErrorMsg);
         return "";
      }

      string setClause = "";
      for (int i = 0; i < ArraySize(columns); i++)
      {
         if (i > 0)
            setClause += ", ";
         if (values[i] == "NULL")
            setClause += columns[i] + " = NULL";
         else
         setClause += columns[i] + " = '" + values[i] + "'";
      }

      string query = "UPDATE " + m_table + " SET " + setClause;
      query += " " + m_whereClause;
      return query;
   }

   string BuildDeleteQuery()
   {
      if (m_whereClause == "")
      {
         m_lastStatus = QUERY_ERROR_EXECUTION;
         m_lastErrorMsg = "Warning: DELETE without WHERE clause. Use DeleteAll() if intentional.";
         Log(m_lastErrorMsg);
         return "";
      }
      return "DELETE FROM " + m_table + " " + m_whereClause;
   }

 public:
   QueryBuilder(IDatabaseDriver *driver) : m_driver(driver),
                                           m_logEnabled(true)
   {
      Reset();
   }

   //+------------------------------------------------------------------+
   //| Reset query builder state                                        |
   //+------------------------------------------------------------------+
   void Reset()
   {
      m_table = "";
      ClearQueryState();
      m_lastStatus = QUERY_OK;
      m_lastErrorMsg = "";
   }

   QueryBuilder *SetLogging(bool enable)
   {
      m_logEnabled = enable;
      return GetPointer(this);
   }

   //+------------------------------------------------------------------+
   //| Table selection                                                  |
   //+------------------------------------------------------------------+
   QueryBuilder *Table(string table)
   {
      m_table = table;
      ClearQueryState();
      return GetPointer(this);
   }

   //+------------------------------------------------------------------+
   //| Select fields                                                    |
   //+------------------------------------------------------------------+
   QueryBuilder *Select(string fields = "*")
   {
      m_selectFields = fields;
      return GetPointer(this);
   }

   //+------------------------------------------------------------------+
   //| Where conditions                                                 |
   //+------------------------------------------------------------------+
   QueryBuilder *Where(string column, string op, string value)
   {
      string condition = column + " " + op + " '" + value + "'";
      if (m_whereClause == "")
         m_whereClause = "WHERE " + condition;
      else
         m_whereClause += " AND " + condition;
      return GetPointer(this);
   }

   QueryBuilder *Where(string column, string value)
   {
      return Where(column, "=", value);
   }

   // Overloaded methods for numeric values (without quotes)
   QueryBuilder *Where(string column, string op, long value)
   {
      string condition = column + " " + op + " " + IntegerToString(value);
      if (m_whereClause == "")
         m_whereClause = "WHERE " + condition;
      else
         m_whereClause += " AND " + condition;
      return GetPointer(this);
   }

   QueryBuilder *Where(string column, string op, double value)
   {
      string condition = column + " " + op + " " + DoubleToString(value);
      if (m_whereClause == "")
         m_whereClause = "WHERE " + condition;
      else
         m_whereClause += " AND " + condition;
      return GetPointer(this);
   }

   QueryBuilder *Where(string column, long value)
   {
      return Where(column, "=", value);
   }

   QueryBuilder *Where(string column, double value)
   {
      return Where(column, "=", value);
   }

   QueryBuilder *OrWhere(string column, string op, string value)
   {
      string condition = column + " " + op + " '" + value + "'";
      if (m_whereClause == "")
         m_whereClause = "WHERE " + condition;
      else
         m_whereClause += " OR " + condition;
      return GetPointer(this);
   }

   QueryBuilder *OrWhere(string column, string value)
   {
      return OrWhere(column, "=", value);
   }

   QueryBuilder *OrWhere(string column, string op, long value)
   {
      string condition = column + " " + op + " " + IntegerToString(value);
      if (m_whereClause == "")
         m_whereClause = "WHERE " + condition;
      else
         m_whereClause += " OR " + condition;
      return GetPointer(this);
   }

   QueryBuilder *OrWhere(string column, string op, double value)
   {
      string condition = column + " " + op + " " + DoubleToString(value);
      if (m_whereClause == "")
         m_whereClause = "WHERE " + condition;
      else
         m_whereClause += " OR " + condition;
      return GetPointer(this);
   }

   QueryBuilder *WhereIn(string column, string &values[])
   {
      string condition = column + " IN (";
      for (int i = 0; i < ArraySize(values); i++)
      {
         if (i > 0)
            condition += ", ";
         condition += "'" + values[i] + "'";
      }
      condition += ")";

      if (m_whereClause == "")
         m_whereClause = "WHERE " + condition;
      else
         m_whereClause += " AND " + condition;
      return GetPointer(this);
   }

   QueryBuilder *WhereBetween(string column, string min, string max)
   {
      string condition = column + " BETWEEN '" + min + "' AND '" + max + "'";
      if (m_whereClause == "")
         m_whereClause = "WHERE " + condition;
      else
         m_whereClause += " AND " + condition;
      return GetPointer(this);
   }

   QueryBuilder *WhereNull(string column)
   {
      string condition = column + " IS NULL";
      if (m_whereClause == "")
         m_whereClause = "WHERE " + condition;
      else
         m_whereClause += " AND " + condition;
      return GetPointer(this);
   }

   QueryBuilder *WhereNotNull(string column)
   {
      string condition = column + " IS NOT NULL";
      if (m_whereClause == "")
         m_whereClause = "WHERE " + condition;
      else
         m_whereClause += " AND " + condition;
      return GetPointer(this);
   }

   //+------------------------------------------------------------------+
   //| Join methods                                                     |
   //+------------------------------------------------------------------+
   QueryBuilder *Join(string table, string first, string op, string second)
   {
      m_joinClause += " JOIN " + table + " ON " + first + " " + op + " " + second;
      return GetPointer(this);
   }

   QueryBuilder *LeftJoin(string table, string first, string op, string second)
   {
      m_joinClause += " LEFT JOIN " + table + " ON " + first + " " + op + " " + second;
      return GetPointer(this);
   }

   QueryBuilder *RightJoin(string table, string first, string op, string second)
   {
      m_joinClause += " RIGHT JOIN " + table + " ON " + first + " " + op + " " + second;
      return GetPointer(this);
   }

   //+------------------------------------------------------------------+
   //| Order by                                                         |
   //+------------------------------------------------------------------+
   QueryBuilder *OrderBy(string column, string direction = "ASC")
   {
      if (m_orderClause == "")
         m_orderClause = "ORDER BY " + column + " " + direction;
      else
         m_orderClause += ", " + column + " " + direction;
      return GetPointer(this);
   }

   QueryBuilder *OrderByDesc(string column)
   {
      return OrderBy(column, "DESC");
   }

   //+------------------------------------------------------------------+
   //| Group by                                                         |
   //+------------------------------------------------------------------+
   QueryBuilder *GroupBy(string column)
   {
      if (m_groupClause == "")
         m_groupClause = "GROUP BY " + column;
      else
         m_groupClause += ", " + column;
      return GetPointer(this);
   }

   //+------------------------------------------------------------------+
   //| Having                                                           |
   //+------------------------------------------------------------------+
   QueryBuilder *Having(string column, string op, string value)
   {
      string condition = column + " " + op + " '" + value + "'";
      if (m_havingClause == "")
         m_havingClause = "HAVING " + condition;
      else
         m_havingClause += " AND " + condition;
      return GetPointer(this);
   }

   //+------------------------------------------------------------------+
   //| Limit                                                            |
   //+------------------------------------------------------------------+
   QueryBuilder *Limit(int limit)
   {
      m_limitClause = "LIMIT " + IntegerToString(limit);
      return GetPointer(this);
   }

   QueryBuilder *Take(int limit)
   {
      return Limit(limit);
   }

   //+------------------------------------------------------------------+
   //| Execute SELECT query and return result                          |
   //+------------------------------------------------------------------+
   int Get()
   {
      if (!IsConnected())
         return INVALID_HANDLE;

      string query = BuildSelectQuery();
      ClearQueryState();

      if (query == "")
         return INVALID_HANDLE;

      Log("Executing query:", query);

      int request = m_driver.Prepare(query);

      if (request == INVALID_HANDLE)
      {
         m_lastStatus = QUERY_ERROR_PREPARATION;
         m_lastErrorMsg = m_driver.GetLastErrorMsg();
         Log(m_lastErrorMsg);
         return INVALID_HANDLE;
      }

      m_lastStatus = QUERY_OK;
      return request;
   }

   //+------------------------------------------------------------------+
   //| Get first record                                                 |
   //+------------------------------------------------------------------+
   int First()
   {
      Limit(1);
      return Get();
   }

   //+------------------------------------------------------------------+
   //| Count records                                                    |
   //+------------------------------------------------------------------+
   long Count()
   {
      if (!IsConnected())
         return -1;

      string query = BuildSelectQuery(true);
      ClearQueryState();

      if (query == "")
         return -1;

      Log("Executing query:", query);
      int request = m_driver.Prepare(query);

      if (request == INVALID_HANDLE)
      {
         m_lastStatus = QUERY_ERROR_PREPARATION;
         m_lastErrorMsg = m_driver.GetLastErrorMsg();
         Log(m_lastErrorMsg);
         return -1;
      }

      long count = -1;
      if (m_driver.Read(request))
      {
         if (!m_driver.ColumnLong(request, 0, count))
         {
            m_lastStatus = QUERY_ERROR_READ;
            m_lastErrorMsg = "Failed to read count column.";
            Log(m_lastErrorMsg);
            count = -1;
         }
      }
      else
      {
         m_lastStatus = QUERY_ERROR_READ;
         m_lastErrorMsg = "DatabaseRead failed.";
         Log(m_lastErrorMsg);
      }

      m_driver.Finalize(request);
      if (count != -1)
         m_lastStatus = QUERY_OK;

      return count;
   }

   //+------------------------------------------------------------------+
   //| Insert data                                                      |
   //+------------------------------------------------------------------+
   bool Insert(string &columns[], string &values[])
   {
      if (!IsConnected())
         return false;

      string query = BuildInsertQuery(columns, values);

      ClearQueryState();

      if (query == "")
         return false;

      Log("Executing query:", query);
      if (!m_driver.Execute(query))
      {
         m_lastStatus = QUERY_ERROR_EXECUTION;
         m_lastErrorMsg = m_driver.GetLastErrorMsg();
         Log(m_lastErrorMsg);
         return false;
      }

      m_lastStatus = QUERY_OK;
      return true;
   }

   //+------------------------------------------------------------------+
   //| Update data                                                      |
   //+------------------------------------------------------------------+
   bool Update(string &columns[], string &values[])
   {
      if (!IsConnected())
         return false;

      string query = BuildUpdateQuery(columns, values);

      ClearQueryState();

      if (query == "")
         return false;

      Log("Executing query:", query);
      if (!m_driver.Execute(query))
      {
         m_lastStatus = QUERY_ERROR_EXECUTION;
         m_lastErrorMsg = m_driver.GetLastErrorMsg();
         Log(m_lastErrorMsg);
         return false;
      }

      m_lastStatus = QUERY_OK;
      return true;
   }

   //+------------------------------------------------------------------+
   //| Delete data                                                      |
   //+------------------------------------------------------------------+
   bool Delete()
   {
      if (!IsConnected())
         return false;

      string query = BuildDeleteQuery();

      ClearQueryState();

      if (query == "")
         return false;

      Log("Executing query:", query);
      if (!m_driver.Execute(query))
      {
         m_lastStatus = QUERY_ERROR_EXECUTION;
         m_lastErrorMsg = m_driver.GetLastErrorMsg();
         Log(m_lastErrorMsg);
         return false;
      }

      m_lastStatus = QUERY_OK;
      return true;
   }

   //+------------------------------------------------------------------+
   //| Delete all records (explicit method)                            |
   //+------------------------------------------------------------------+
   bool DeleteAll()
   {
      if (!IsConnected())
         return false;

      ClearQueryState();

      string query = "DELETE FROM " + m_table;
      Log("Executing query:", query);

      if (!m_driver.Execute(query))
      {
         m_lastStatus = QUERY_ERROR_EXECUTION;
         m_lastErrorMsg = m_driver.GetLastErrorMsg();
         Log(m_lastErrorMsg);
         return false;
      }

      m_lastStatus = QUERY_OK;
      return true;
   }

   //+------------------------------------------------------------------+
   //| Raw query execution (for queries that don't return results)      |
   //+------------------------------------------------------------------+
   bool Raw(string query)
   {
      if (!IsConnected())
         return false;

      ClearQueryState();

      Log("Executing raw query:", query);

      if (!m_driver.Execute(query))
      {
         m_lastStatus = QUERY_ERROR_EXECUTION;
         m_lastErrorMsg = m_driver.GetLastErrorMsg();
         Log(m_lastErrorMsg);
         return false;
      }

      m_lastStatus = QUERY_OK;
      return true;
   }

   //+------------------------------------------------------------------+
   //| Check if record exists                                           |
   //+------------------------------------------------------------------+
   bool Exists()
   {
      return Count() > 0;
   }

   //+------------------------------------------------------------------+
   //| Methods for getting status                                       |
   //+------------------------------------------------------------------+
   ENUM_QUERY_STATUS GetLastStatus() const
   {
      return m_lastStatus;
   }
   string GetLastError() const
   {
      return m_lastErrorMsg;
   }
};
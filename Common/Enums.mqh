//+------------------------------------------------------------------+
//| Enumerations and constants                                       |
//+------------------------------------------------------------------+

/**
 * @enum ENUM_DATABASE_TYPE
 * Types of supported databases.
 */
enum ENUM_DATABASE_TYPE
{
   DB_SQLITE,
   DB_POSTGRESQL,
   DB_MYSQL
};

/**
 * @enum ENUM_QUERY_STATUS
 * Status codes for database operations.
 */
enum ENUM_QUERY_STATUS
{
   QUERY_OK,
   QUERY_ERROR_CONNECTION,
   QUERY_ERROR_PREPARATION,
   QUERY_ERROR_EXECUTION,
   QUERY_ERROR_READ,
   QUERY_ERROR_NO_TABLE,
   QUERY_ERROR_INVALID_ARGUMENTS,
   QUERY_ERROR_NOT_IMPLEMENTED
};
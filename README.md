# DataBase (DB)

### Example

```mql5
#include <MqlSystems/DB/QueryBuilder.mqh>

void OnStart()
{
    QueryBuilder qb;
    qb.select("name, age");
    qb.From("users");
    qb.where("age", ">", "20");
    qb.orderBy("name");
    qb.get();
}
```
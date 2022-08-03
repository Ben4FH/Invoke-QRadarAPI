

## Search-QRadar

* Performs and AQL search in QRadar and returns the results.

### Parameters

* **Query** -  The AQL query that you want to use in your search.
  * Use [Here-Strings](https://devblogs.microsoft.com/scripting/powertip-use-here-strings-with-powershell/) to enter a query over multiple lines

* **SavedSearch** - The name of a saved search that you want to run.

* **Export** - The name of the file you want to export the results to.
  * Possible values include: "C:\users\username\desktop\results.csv", "results.csv", "results"
  * This is used in combination with one of the 4 possible format switches (CSV, JSON, XML, Text)

* **CSV** - Return results in CSV format.

* **JSON** - Return results in JSON format.

* **XML** - Return results in XML format.

* **Text** - Return results in a fancy text table.

### Example Usage

```
PS C:\Users\Ben> Search-QRadar -Query "SELECT sourceip, count(*) FROM events GROUP by sourceip LAST 7 days" -Text
Waiting for search to complete...

Will check again in 5 seconds...
Will check again in 5 seconds...

Collecting results...

--------------------------
| sourceip     | COUNT   |
--------------------------
| 172.16.1.2   | 65166.0 |
| 172.16.1.202 | 2490.0  |
| 172.16.2.2   | 2.0     |
| 172.16.2.3   | 765.0   |
| 172.16.2.4   | 2.0     |
| 172.16.2.5   | 2.0     |
| 172.16.2.200 | 173.0   |
| 172.16.2.201 | 271.0   |
| 127.0.0.1    | 314.0   |
--------------------------
```
```
PS C:\Users\Ben> Search-QRadar -Query @"
>> SELECT sourceip, count(*)
>> FROM events
>> GROUP BY sourceip
>> LAST 7 days
>> "@ -JSON
Waiting for search to complete...

Will check again in 5 seconds...
Will check again in 5 seconds...

Collecting results...

{
    "events":  [
                   {
                       "sourceip":  "172.16.1.2",
                       "COUNT":  65166.0
                   },
                   {
                       "sourceip":  "172.16.1.202",
                       "COUNT":  2490.0
                   },
                   {
                       "sourceip":  "172.16.2.2",
                       "COUNT":  2.0
                   },
                   {
                       "sourceip":  "172.16.2.3",
                       "COUNT":  765.0
                   },
                   {
                       "sourceip":  "172.16.2.4",
                       "COUNT":  2.0
                   },
                   {
                       "sourceip":  "172.16.2.5",
                       "COUNT":  2.0
                   },
                   {
                       "sourceip":  "172.16.2.200",
                       "COUNT":  173.0
                   },
                   {
                       "sourceip":  "172.16.2.201",
                       "COUNT":  271.0
                   },
                   {
                       "sourceip":  "127.0.0.1",
                       "COUNT":  314.0
                   }
               ]
}
```
```
PS C:\Users\Ben> Search-QRadar -SavedSearch "Event Count by Source IP" -Export "sources.csv" -CSV
Looking for saved search called 'Event Count by Source IP'...

Waiting for search to complete...

Will check again in 5 seconds...

Collecting results...

Results have been saved to sources.csv
```
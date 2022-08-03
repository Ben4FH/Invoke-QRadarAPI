

## Get-Assets

* Returns a list of assets in QRadar and their properties.
* Without any parameters it returns all the assets in QRadar
* Multiple parameters can be specified to filter the list down

### Parameters

* **Domains** - The name of the domain which the assets belong to.
* **Export** - The name of the file you want to export the results to.
  * Possible values include: "C:\users\username\desktop\assets.csv", "assets.csv", "assets"
* **Hostnames** - A hostname that you want to filter. You can do a partial search with a wildcard
  * Ex. "*PROD*" will find assets that contain PROD
  * Multiple hostnames can be specified and you can use the -Or switch to look multiple hosts
  * Ex. "*PROD*","*SQL*" -Or 
* **IpAddresses** - An IP address you want to filter. You can also do a partial search with a wildcard.
  * Ex. "192.168.*" will find IP addresses that start with 192.168.
  * Multiple addresses can be specified and you can use the -Or switch to look multiple hosts
  * Ex. "192.168.*","10.*" -Or
* **Or** - Use this switch with multiple filters to apply the OR operator to them.
* **Properties** - Specify the name of a system or custom property
  * If you use this you must also use the -PropValues parameter
  * You can specify multiple property names, delimited by a comma
  * Ex. -Properties "Description","Location" -PropValues "*SQL*","London"
* **PropValues** - Specify the values which correspond to the -Properties property names.
  * The value will be assigned to the property name with the same index number.
  * Ex. -Properties "Description","Location" -PropValues "*SQL*","London"
    * "*SQL*" is related to "Description" because they are both at index 0. Similarly "London" and "Location" are at index 1

### Example Usage

```
PS C:\Users\Ben> Get-Assets -Properties "Given Name" -PropValues "CPY*"


IP Last Seen      :
ID                : 1001
Username          :
Domain ID         : 0
Hostnames         :
Vuln Count        : 0
IP                : 172.16.2.2
Risk Score Sum    : 0.0
Description       : Client Workstation
User Supplied OS  : Windows Server 2019
Location          : London
Asset Type        : Server
Technical Owner   : Server Team
Weight            : 0
Technical Contact : serverteam@company.com
Given Name        : CPY-CLIENT-1
Unified Name      : CPY-CLIENT-1.company.local

IP Last Seen      :
ID                : 1004
Username          :
Domain ID         : 0
Hostnames         :
Vuln Count        : 0
IP                : 172.16.2.5
Risk Score Sum    : 0.0
Unified Name      : CPY-CLIENT-2.company.local
Given Name        : CPY-CLIENT-2
Weight            : 0
Description       : Client Workstation
User Supplied OS  : Windows Server 2019
Technical Owner   : Server Team
Asset Type        : Server
Technical Contact : serverteam@company.com
Location          : London
```
```
PS C:\Users\Ben> Get-Assets -Properties "Description","Location" -PropValues "Domain Controller","London"


IP Last Seen      :
ID                : 1002
Username          :
Domain ID         : 0
Hostnames         :
Vuln Count        : 0
IP                : 172.16.2.3
Risk Score Sum    : 0.0
Asset Type        : Server
Unified Name      : DC01.company.local
Technical Contact : serverteam@company.com
Weight            : 0
Description       : Domain Controller
Location          : London
Given Name        : DC01
User Supplied OS  : Windows Server 2019
Technical Owner   : Server Team
```
```
PS C:\Users\Ben> Get-Assets -IpAddresses "172.16.2.2","172.16.2.3" -Or


IP Last Seen      :
ID                : 1001
Username          :
Domain ID         : 0
Hostnames         :
Vuln Count        : 0
IP                : 172.16.2.2
Risk Score Sum    : 0.0
Description       : Client Workstation
User Supplied OS  : Windows Server 2019
Location          : London
Asset Type        : Server
Technical Owner   : Server Team
Weight            : 0
Technical Contact : serverteam@company.com
Given Name        : CPY-CLIENT-1
Unified Name      : CPY-CLIENT-1.company.local

IP Last Seen      :
ID                : 1002
Username          :
Domain ID         : 0
Hostnames         :
Vuln Count        : 0
IP                : 172.16.2.3
Risk Score Sum    : 0.0
Asset Type        : Server
Unified Name      : DC01.company.local
Technical Contact : serverteam@company.com
Weight            : 0
Description       : Domain Controller
Location          : London
Given Name        : DC01
User Supplied OS  : Windows Server 2019
Technical Owner   : Server Team
```

```
PS C:\Users\Ben> Get-Assets -Export all_assets.csv
Results have been saved to all_assets.csv
```
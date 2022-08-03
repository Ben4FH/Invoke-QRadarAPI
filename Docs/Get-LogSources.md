

## Get-LogSources

* Returns a list of logsources from QRadar

### Parameters

* **Group** -  Allows you to only want to collect log sources from a specific log source group.

* **Before** - A switch which is used in combination with the Days or Hours parameter to specify that you want to filter for log sources that have evented **BEFORE** a period of time.
  * -Before -Days 1 means to show log sources that have not evented in the past day.

* **After** - A switch which is used in combination with the Days or Hours parameter to specify that you want to filter for log sources that have evented **AFTER** a period of time.
  * -After -Hours 2 means to show log sources that have evented in the past 2 hours.

* **Days** - Specifies the number of days to take away from the current time.

* **Hours** - Specifies the number of hours to take away from the current time.

* **Descending** - Shows the results where the most recent date is at the top and ther oldest is at the bottom.

* **Output** - Allows you to output the resulting table to a csv file. You can either specify the full path or just the file name if you want it to export to the current folder


### Example Usage

```
PS C:\Users\Ben> Get-LogSources -Group EUDs

Log Source                      Type                                 Groups Last Event Time
----------                      ----                                 ------ ---------------
WindowsAuthServer @ MSEDGEWIN10 Microsoft Windows Security Event Log EUDs   17 April 2021 11:29:21
Total Log Sources: 1

PS C:\Users\Ben> Get-LogSources -Before -Hours 12

Log Source                      Type                                 Groups          Last Event Time
----------                      ----                                 ------          ---------------
pfsense                         pfSense                              Firewalls       Never
LinuxServer @ kali              Linux OS                             Linux Servers   16 April 2021 10:37:18
WindowsAuthServer @ MSEDGEWIN10 Microsoft Windows Security Event Log EUDs            16 April 2021 11:29:21
Suricata IDS                    Snort Open Source IDS                Linux Servers   16 April 2021 13:10:10
DNS Traffic @ Zeek              Zeek - DNS Traffic                   Linux Servers   16 April 2021 13:12:26
WindowsAuthServer @ DC01        Microsoft Windows Security Event Log Windows Servers 16 April 2021 13:12:28
Total Log Sources: 6

PS C:\Users\Ben> Get-LogSources -Before -Hours 12 -Descending

Log Source                      Type                                 Groups          Last Event Time
----------                      ----                                 ------          ---------------
WindowsAuthServer @ DC01        Microsoft Windows Security Event Log Windows Servers 16 April 2021 13:12:28
DNS Traffic @ Zeek              Zeek - DNS Traffic                   Linux Servers   16 April 2021 13:12:26
Suricata IDS                    Snort Open Source IDS                Linux Servers   16 April 2021 13:10:10
WindowsAuthServer @ MSEDGEWIN10 Microsoft Windows Security Event Log EUDs            16 April 2021 11:29:21
LinuxServer @ kali              Linux OS                             Linux Servers   16 April 2021 10:37:18
pfsense                         pfSense                              Firewalls       Never
Total Log Sources: 6

PS C:\Users\Ben> Get-LogSources -After -Days 0.5 -Output logsources
Output has been saved to logsources.csv

Log Source           Type Groups Last Event Time
----------           ---- ------ ---------------
Total Log Sources: 0
```
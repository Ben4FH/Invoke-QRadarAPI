# Invoke-QRadarAPI
A Powershell module that can be used to perform several functions using the QRadar REST API

These functions were tested on Qradar Community Edition 7.3.3

To access these functions:
1. Place the folder that contains the module somewhere in your Powershell path ($env:PSModulePath)
2. From Powershell run: Import-Module Invoke-QRadarAPI
3. The first time you call a function it will prompt you to enter the IP of your QRadar instance, and your API key.
   * It will then encrypt your API key and save it along with your IP to file called config.xml in the script root directory.
   * The API key is encrypted using the [Windows Data Protection API](https://docs.microsoft.com/en-us/previous-versions/windows/apps/hh464970(v=win.10)). Not the securest way of storing API keys, but it is better than storing them in plaintext.
4. As long as this file exists in the script root directory, it wont ask you for credentials for any subsequent function calls.

## Get-Assets
* Returns a list of assets from QRadar
* Can apply property filters to return specific assets.

## Update-Assets
* Takes a csv file with a list of asset properties to be updated, and applies the changes in QRadar.

## Get-LogSources
* Retrieves a list of log sources from QRadar.
* Can be used to retrieve log sources from certain groups
* Or can return log sources which havent generated an event in X number of days

## Search-QRadar
* Executes a search in QRadar and returns the results
* Can take an AQL query or the name of a saved search as input
* Can output and export to CSV, JSON, XML or Text Table format.

## Disclaimer

Use these functions at your own risk. I assume no liability for the accuracy, correctness, completeness, usefulness, or any damages.

IBM, the IBM logo, and ibm.com are trademarks or registered trademarks of International Business Machines Corp., registered in many 
jurisdictions worldwide. Other product and service names might be trademarks of IBM or other companies.

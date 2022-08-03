
# Ignore certificate errors

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


function Get-Creds {

    <#
        .SYNOPSIS
        Imports IP address and token, which is required to make API requests

        .DESCRIPTION
        Get-Creds checks to see if a config.xml file exists in the script root directory.
        If the file doesnt exist it will prompt the user to enter the IP address in the username field
        and the API key in the password field. It will then export them to an xml file.
        The API key will be encrypted using the Windows Data Protection API, which ensures that only
        your user account can decrypt the contents. Finally it will import the credentials and return them
        to be used to make API requests.

        .NOTES
        Creation Date:  16/04/2021
        Last Updated:  05/05/2021

    #>

    # Check to see if config file already exists, otherwise it will prompt for creds and create a new one.
    if (!(Test-Path $PSScriptRoot\config.xml)) {

        Write-Host "Config file doesn't exist. Let's create one." -ForegroundColor Yellow
        Get-Credential -Credential (Get-Credential -Message "Username = QRadar IP, Password = API Key") | Export-Clixml "$PSScriptRoot\config.xml"
    }

    # Import IP and encrypted API key
    $credentials = Import-Clixml "$PSScriptRoot\config.xml" -ErrorAction Stop
    $ip = $credentials.UserName
    $token = $credentials.GetNetworkCredential().Password

    return $ip, $token
    }


function Update-Assets {

    <#
        .SYNOPSIS
        Updates information about assets which already exist in QRadar

        .DESCRIPTION
        Update-Assets is a Powershell function that will update information regarding assets, such as
        their name, IP address, description, location or owner. This function only works if the name of the asset
        you want to update, already exists in QRadar.

        .PARAMETER File
        The csv file which contains the information you need to update in QRadar. The header row must contain
        valid property names and their id, separated by a colon.

        .NOTES
        Creation Date:  16/04/2021
        Last Updated:  16/04/2021
  
        .EXAMPLE
        Update-Assets -File asset_updates.csv

        .EXAMPLE
        Update-Assets -File "C:\admin\Documents\asset_updates.csv"

    #>

    [CmdletBinding()]

    param (

        [Parameter(Mandatory=$true)][string]$File

        )

    # IP address and token required to make API requests
    $ip, $token = Get-Creds


    # Get list of assets in QRadar
    $assetList = Invoke-RestMethod -Method GET -ContentType "application/json"-Uri "https://$ip/api/asset_model/assets?fields=id%2Cproperties(name,value)" -Headers @{"SEC"=$token}
    $assetList = $assetList | Select-Object -Skip 1

    # Error if no assets were retrieved from QRadar.
    if (!($assetList)) {
        Write-Error -Message "No assets were found in QRadar! Ensure that they already exist." -ErrorAction Stop
    }
   

    # Import list of assets to be updated
    $assetsToUpdate = Get-Content -Path $File

    # Remove the words from the header, leaving only the ID numbers
    $assetsToUpdate[0] = ($assetsToUpdate[0] -replace '(\D+:)', ",") -replace '^[,]', ''

    # Create object with new header values
    $assetsToUpdate = $assetsToUpdate | Select-Object -Skip 1 | ConvertFrom-String -Delimiter ',' -PropertyNames ($assetsToUpdate[0] -split ',')

    # Format the property ID numbers and create a list out of them
    $propertyIDNumbers = ($assetsToUpdate | ConvertTo-Csv -NoTypeInformation -Delimiter ',' | select -First 1 | % { $_ -replace '["]', ""}) -split ','
    $numberOfAssets = @($assetsToUpdate).Length

    # Loop through each host to be updated
    for($i=0; $i -lt $numberOfAssets; $i++){

        # Create empty array
        $OutputObj = @()

        # Create a hashtable for the property ID and matching value and add it to the array
        foreach ($propertyIDNumber in $propertyIDNumbers) {

            # Ignore if the property was not filled out in the csv
            if ($assetsToUpdate[$i].$propertyIDNumber -ne ''){
                $OutputObj += New-Object -TypeName PSobject -Property @{
                    type_id = "$propertyIDNumber"
                    value = $assetsToUpdate[$i] | select -ExpandProperty $propertyIDNumber}
            }
        }


        # Get the data in valid format for the POST request
        $body = @{properties=@($OutputObj)} | ConvertTo-Json

        Write-Host "Updating asset $($i+1) out of $numberOfAssets..." -ForegroundColor Cyan

        # Search in the Given Name field of QRadar Assets for the matching name in the CSV and return the index
        $index = ($assetList.properties | ? {$_.name -eq "Given Name"}).value.IndexOf($assetsToUpdate[$i].1001) 

        # Skip if no matching Given Name was found, otherwise update the asset in QRadar
        if ($index -eq -1) {
            Write-Error -Message "$($assetsToUpdate[$i].1001) cannot be found in QRadar..." -ErrorAction Continue
        }
        else {
            $assetID = $assetList[$index].id
            Invoke-RestMethod -Method POST -body $body -ContentType "application/json"-Uri "https://$ip/api/asset_model/assets/$assetID" -Headers @{"SEC"=$token}
        }
        
    }

    Write-Host "`nFinished!" -ForegroundColor Green
}



function Get-LogSources {

    <#
        .SYNOPSIS
        Gets a list of Log Sources in QRadar

        .DESCRIPTION
        Get-LogSources is a Powershell function that will query the QRadar REST API to pull a list of 
        log sources, from log source management. It can be used to find log sources that are not eventing.

        .PARAMETER Group
        The name of the group for which contains the logsources you want to find. The name has to be
        identical to how your log source group is set up in QRadar.

        .PARAMETER After
        This asserts that you want to find log sources where the last event time is AFTER a date.
        By default this date will be 0 days and 0 hours ago but can be explicitly specified using 
        the Days or Hours parameter.
        
        .PARAMETER Before
        This asserts that you want to find log sources where the last event time is BEFORE a date.
        By default this date will be 0 days and 0 hours ago but can be explicitly specified using 
        the Days or Hours parameter

        .PARAMETER Days
        This will only have an effect when used with either the After or Before parameter, and defines
        the number of days to go back when filtering the last event date field

        .PARAMETER Hours
        This will only have an effect when used with either the After or Beforee parameter, and defines
        the number of hours to go back when filtering the last event date field.

        .PARAMETER Descending
        By default, the table output shows the dates in ascending order. This switch will flip the order.

        .PARAMETER Output
        Specifies the path or name of a file in which the table output will be exported to in csv format.

        .NOTES
        Creation Date:  16/04/2021
        Last Updated:  16/04/2021
  
        .EXAMPLE
        Get-LogSources -Group Firewalls -After -Days 7

        .EXAMPLE
        Get-LogSources -Before -Hours 12 -Output "C:\temp\output.csv"

        .EXAMPLE
        Get-LogSources -After -Hours 0.5 -Descending
    #>

    [CmdletBinding()]

    param (

        [switch]$After,
        [switch]$Before,
        [decimal]$Days,
        [switch]$Descending,
        [string]$Group,
        [decimal]$Hours,
        [string]$Output
            
        )

        # IP address and token required to make API requests
        $ip, $token = Get-Creds

        # Get list of all log source types
        $types_uri = "https://$ip/api/config/event_sources/log_source_management/log_source_types?fields=name%2C%20id"
        $types = Invoke-RestMethod -Method GET -ContentType "application/json" -Uri $types_uri -Headers @{"SEC"=$token}

        # Get list of all log source groups
        $groups_uri = "https://$ip/api/config/event_sources/log_source_management/log_source_groups?fields=name%2C%20id"
        $groups = Invoke-RestMethod -Method GET -ContentType "application/json" -Uri $groups_uri -Headers @{"SEC"=$token}

        
        # If a group was specified, check that it is valid and use the uri which filters for that group
        # Otherwise use the uri which shows all log sources from all groups

        if ($Group) {

            if (!($Group -in $groups.name)) {

                Write-Error -Message "Invalid group name" -ErrorAction Stop
            }

            else {

                $group_id = ($groups | ? {$_.name -eq $Group}).id
                
                # The filter on this url ignores the log sources which have ':: qradar' in the name
                $uri = "https://$ip/api/config/event_sources/log_source_management/log_sources?fields=name%2Ctype_id%2Cgroup_ids%2Clast_event_time&filter=name%20not%20ilike%20%20%22%25%3A%3A%20qradar%22%20and%20group_ids%20contains%20" + $group_id

            }

        }

        else {

            $uri = "https://$ip/api/config/event_sources/log_source_management/log_sources?fields=name%2Ctype_id%2Cgroup_ids%2Clast_event_time&filter=name%20not%20ilike%20%20%22%25%3A%3A%20qradar%22"

        }

        # If no days or hours were specified, default to 0    
        if (!($Days)){$Days = 0}
        if (!($Hours)){$Hours = 0}

        # Get list of log sources
        $logSources = Invoke-RestMethod -Method GET -ContentType "application/json" -Uri $uri -Headers @{"SEC"=$token}

        # Set the date/time format to your current date culture
        $CultureDateTimeFormat = (Get-Culture).DateTimeFormat
        $DateTimeFormat = $CultureDateTimeFormat.FullDateTimePattern

        # Convert the last event time from unix to human readable, and resolve the group/type IDs to their names
        foreach ($logSource in $logSources) {

            $logSource.last_event_time = $(([System.DateTimeOffset]::FromUnixTimeMilliseconds($logSource.last_event_time)).DateTime).ToString($DateTimeFormat)
            $logSource.group_ids = ($groups | ? {$_.id -in $logSource.group_ids}).name -join ','
            $logSource.type_id = ($types | ? {$_.id -eq $logSource.type_id}).name

        }
        

        # If specified, filter for log sources that have evented after X number of days and hours ago
        if ($After) {

            $logSources = $logSources | ? {[datetime]$_.last_event_time -ge ([datetime](Get-Date -Format $DateTimeFormat)).AddDays(-$Days).AddHours(-$Hours)} | Sort-Object last_event_time

        }

        # If specified, filter for log sources that have evented before X number of days and hours ago
        if ($Before) {

            $logSources = $logSources | ? {[datetime]$_.last_event_time -lt ([datetime](Get-Date -Format $DateTimeFormat)).AddDays(-$Days).AddHours(-$Hours)} | Sort-Object last_event_time

        }
            

        # If specified, sort the last event time in descending order, otherwise sort in ascending order
        if ($Descending) {

            $logSources = $logSources | Sort-Object {[datetime]$_.last_event_time} -Descending

        }

        else {

            $logSources = $logSources | Sort-Object {[datetime]$_.last_event_time}

        }
            

        # Add a row with the total number of log sources that were returned
        [array]$logSources += @{name="Total Log Sources: $($logSources.name.count)"}
        

        # Update column names and remove dates that have the year 1970 as it means they have never evented
        $logSources = $logSources | Select-Object `
            @{N='Log Source'; E={$_.name}}, 
            @{N='Type'; E={$_.type_id}}, 
            @{N='Groups'; E={$_.group_ids}}, 
            @{N='Last Event Time'; E={$_.last_event_time -replace '.*?1970.*', 'Never'}}
              

        # Output to a csv file
        if($Output) {

            # Add extension if not already specified
            if (!($Output -ilike '*.csv')){ $Output += ".csv"}

            try {

                $logSources | Export-Csv $Output -NoTypeInformation
                Write-Host "Output has been saved to $Output`n" -ForegroundColor Green
            }

            catch {

                Write-Error -Exception $error[0].Exception.Message

            }
        }

        return $logSources
    }

function Search-QRadar {


    <#
        .SYNOPSIS
        Performs an AQL search in QRadar and returns the result.

        .DESCRIPTION
        Search-Qradar is a Powershell function that allows you to pass an AQL query, or the name of a
        saved search, and it will launch a search using the QRadar REST API. The results can be returned
        in CSV, JSON, XML, or a text table format.

        .PARAMETER Query
        The AQL query that you want to use in the search. You can write your query over multiple lines by
        using a here string - https://devblogs.microsoft.com/scripting/powertip-use-here-strings-with-powershell/

        .PARAMETER SavedSearch
        Here you would specify the name of a saved search in QRadar.

        .PARAMETER Export
        Specify the file name with or without a path, for which the results will be exported to.
        
        .PARAMETER CSV
        Output to CSV format

        .PARAMETER JSON
        Output to JSON format

        .PARAMETER XML
        Output to an XmlDocument format

        .PARAMETER Text
        Output to a fancy text table.

        .NOTES
        Creation Date:  04/05/2021
        Last Updated:  06/05/2021
  
        .EXAMPLE
        Search-QRadar -Query "SELECT sourceip FROM events GROUP BY sourceip LAST 24 hours" -CSV

        .EXAMPLE
        Search-QRadar -Query @"
        SELECT sourceip
        FROM events
        GROUP BY sourceip 
        LAST 24 hours
        "@ -Text

        .EXAMPLE
        Search-QRadar -SavedSearch "Outbound Firewall Allows" -CSV -Export "outbound_allows.csv"
    #>

    [CmdletBinding()]

    param (

        [string]$Query,
        [string]$SavedSearch,
        [switch]$CSV,
        [switch]$JSON,
        [switch]$XML,
        [switch]$Text,
        [string]$Export

        )

    # Only 1 output format can be specified
    if (1 -ne $CSV.IsPresent + $JSON.IsPresent + $XML.IsPresent + $Text.IsPresent) {

        Write-Error -Message "Output format not specified. 1 of CSV,JSON,XML,Text needs to be selected." -ErrorAction Stop

    }

    # The function wont run without either a query or a saved search
    elseif (!($Query -xor $SavedSearch)) {

        Write-Error -Message "You must use either a query or a saved search, but not both." -ErrorAction Stop
    }

    # Import IP and API token
    $ip, $token = Get-Creds


    # If the name of  a saved search is specified
    if ($SavedSearch) {

        # Get a list of saved searches and compare the names with the name provided, in order to find the ID
        Write-Host "Looking for saved search called '$SavedSearch'...`n" -ForegroundColor Yellow
        $allSearchesURI = 'https://$ip/api/ariel/saved_searches?fields=name%2Cid'
        $savedSearches = Invoke-RestMethod -Method GET -ContentType "application/json" -Uri $allSearchesURI -Headers @{"SEC"=$token}
        $savedSearchID = ($SavedSearches | ? {$_.name -eq $SavedSearch}).id

        # Fail if no match
        if (!($savedSearchID)) {

            Write-Error -Message "The search name you provided does not exist." -ErrorAction Stop

        }

        $postURI = "https://$ip/api/ariel/searches?saved_search_id=$savedSearchID"
    }

    # URL encode the AQL query
    elseif ($Query) {

        Add-Type -AssemblyName System.Web
        $encodedQuery = [System.Web.HttpUtility]::UrlEncode($Query)
        $postURI = "https://$ip/api/ariel/searches?query_expression=$encodedQuery" 
                       
    }

    # Tell QRadar to launch a new search
    try {

        $queryRequest = Invoke-RestMethod -Method POST -ContentType "application/json" -Uri $postURI -Headers @{"SEC"=$token}
    
    }

    catch {

        Write-Error -Message $_ -ErrorAction Stop

    }

    $searchID = $queryRequest.search_id    

    Write-Host "Waiting for search to complete...`n" -ForegroundColor Yellow


    # Check status every 5 seconds until the search as completed.
    while ($status -ne "COMPLETED") {
            
        $statusRequest = Invoke-RestMethod -Method GET -ContentType "application/json" -Uri "https://$ip/api/ariel/searches/$searchID" -Headers @{"SEC"=$token}
        $status = $statusRequest.status

        if ($status -in ("CANCELLED","ERROR")) {

            Write-Error -Message "Search Failed" -ErrorAction Stop

        }

        else {

            Write-Host "Will check again in 5 seconds..."
            Start-Sleep -Seconds 5

        }
    }

    Write-Host "`nCollecting results...`n" -ForegroundColor Yellow
        
    # QRadar doesnt return the results in a format which is easy to work with the for average user
    # For example, XML doesnt return the inner xml, json doesnt return raw json, csv cant immediately be exported to a csv
    # The parse strings get used by Invoke-Expression to reformat the results so that they can easily be exported.

    if ($CSV) {

        $format = "application/csv"
        $parseString = "$" + "results" + " | ConvertFrom-Csv | ConvertTo-Csv -NoTypeInformation"
        $extension = ".csv"

    }

    elseif ($JSON) {

        $format = "application/json"
        $parseString = "$" + "results" + " | ConvertTo-Json"
        $extension = ".json"

    }

    elseif ($XML) {

        $format = "application/xml"
        $parseString = "$" + "results" + ".innerxml"
        $extension = ".xml"

    }

    elseif ($Text) {

        $format = "text/table"
        $parseString = "$" + "results"
        $extension = ".txt"
    }

    # Get the results and apply formatting

    $results = Invoke-RestMethod -Method GET -ContentType "application/json" -Uri "https://$ip/api/ariel/searches/$searchID/results" -Headers @{"SEC"=$token;"Accept"=$format}
    
    $resultsFormatted = Invoke-Expression $parseString

    # If required, export the results in the selected format.

    if($Export) {

        # Add extension if not already specified
        if (!($Export -ilike "*"+$extension)){ $Export += $extension}

        try {

            $resultsFormatted | Out-File $Export
            Write-Host "Results have been saved to $Export`n" -ForegroundColor Green
            Start-Sleep 1
        }

        catch {

            Write-Error -Exception $error[0].Exception.Message

        }
    }

    # Return the results
    return $resultsFormatted
}

function Get-Assets {

    <#
        .SYNOPSIS
        Returns a list of assets in QRadar

        .DESCRIPTION
        Get-Assets is a Powershell function that allows you to filter and return a list of assets in QRadar.
        Partial matches can be performed using wilcards, and the results can be exported to a CSV if required.
        You can also filter for multiple values in the same field. If you don't specify any parameters it will
        output every asset.

        .PARAMETER Domains
        The name of the domain which the assets belong to.

        .PARAMETER Export
        Specify the file name with or without a path, for which the results will be exported to.
        
        .PARAMETER Hostnames
        Specify a hostname which you want to filter for. Can use the * wildcard for a partial match.
        To filter multiple hostnames, separate them with a comma. See the examples.

        .PARAMETER IpAddresses
        Specify a IP which you want to filter for. Can use the * wildcard for a partial match.
        To filter multiple IpAddresses, separate them with a comma. See the examples.

        .PARAMETER Or
        Use this switch to apply the OR logic to multiple filters

        .PARAMETER Properties
        Specify the name of a specific property which you want to filter for.
        To filter multiple properties, separate them with a comma. See the examples.

        .PARAMETER PropValues
        Specify the resulting value for the -Property paramater which you want to filter for.
        To filter multiple properties, separate them with a comma. See the examples.

        .NOTES
        Creation Date:  09/05/2021
        Last Updated:  09/05/2021
  
        .EXAMPLE
        Get-Assets -Domains "MyCompany" -Export assets.csv

        .EXAMPLE
        Get-Assets -Hostnames "*PROD*" -Properties "Description" -PropValues "*SQL*"

        .EXAMPLE
        Get-Assets -Properties "Description","Description" -PropValues "SQL","Database" -Or

        .EXAMPLE
        Get-Assets -IpAddresses "172.16.2.*","172.16.3.*" -Or

        .EXAMPLE
        Get-Assets
    #>

    param (

        [array]$Domains,
        [string]$Export,
        [array]$Hostnames,
        [array]$IpAddresses,
        [switch]$Or,
        [array]$Properties,
        [array]$PropValues
            
    )

    # Error if only 1 of Property and PropValue are specified
    if ($Properties -xor $PropValues) {

    Write-Error -Message "To search by property, you must select Property and PropValue" -ErrorAction Stop

    }

    # Import Creds
    $ip, $token = Get-Creds

    # Empty array which filters will be added to
    $filters = @()

    # Find the domain id for the matching domain name. If no match found then error.
    if ($Domains) {

        $domainUri = "https://$ip/api/config/domain_management/domains?fields=name%2Cid"
        $domainNames = Invoke-RestMethod -Method GET -ContentType 'application/json' -Uri $domainUri -Headers @{"SEC"=$token}
        $domainIds = ($domainNames | ? {$_.name -in $Domains}).id

        if (!($domainId)) {
            
            Write-Error -Message "$Domains is not a valid domain name" -ErrorAction Stop
        }

        $filters += '$_."Domain ID" -in $domainIds'

    }

    # Adding filters to the array if the parameter was specified
    if ($Hostnames) {

        $filters += $Hostnames | % {'$_.Hostnames -ilike ' + '"'+ $_ + '"'}

    }

    if ($IpAddresses) {
        
        $filters += $IpAddresses | % {'$_.IP -ilike ' + '"' + $_ + '"'}

    }

    if ($Properties) {

        $i = 0
        $filters += $Properties | % {'$_."' + $_ + '"' + ' -ilike ' + '"' + $($PropValues.GetValue($i)) + '"';$i++}

    }

    # Get a list of all assets in QRadar. The reason why I chose to do it this way rather than using the filters in QRadar
    # is because if you filter by a property, for some reason Invoke-RestMethod wont return any other properties in the response
    # even if you include them in the fields section of the query.

    $assetRequest = Invoke-RestMethod -Method GET -Uri "https://$ip/api/asset_model/assets" -Headers @{"SEC"=$token}

    # Create empty array which will hold information for each device
    $allDeviceObj = @()

    # Loop through each device in the returned JSON and parse some of the important top level fields, as well as all of the properties
    foreach ($device in $assetRequest) { 

        $nonProperties = @{
        "ID"=$device.id;
        "Domain ID"=$device.domain_id;
        "Vuln Count"=$device.vulnerability_count;
        "Risk Score Sum"=$device.risk_score_sum;
        "Hostnames"=$device.hostnames.name;
        "IP"=$device.interfaces.ip_addresses.value;
        "IP Last Seen"=$device.interfaces.last_seen_profiler;
        "Username"=$device.users.username}

        $deviceobj = New-Object psobject -Property $nonProperties

        foreach ($deviceProperty in $device.properties) {

             $deviceobj | Add-Member NoteProperty $deviceProperty.name $deviceProperty.value

        }

        $allDeviceObj += $deviceobj
    }

    # If -Or is specified apply OR logic to the filters, by default AND is used
    if ($Or) {

        $logic = " -or "

    }

    else {

        $logic = " -and "

    }

    # Join all filters in the array and use them in a Where-Object clause to filter the results
    $filters = $filters -join $logic

    # if there are no filters, show all results.
    $filteredResults = $allDeviceObj | ? {if ($filters) {Invoke-Expression $filters} else {$_}}

    # Export results if required
    if ($Export) {

        # Add extension if not already specified
        if (!($Export -ilike "*.csv")){ $Export += ".csv"}

        try {

            $filteredResults | Export-Csv $Export -NoTypeInformation
            Write-Host "Results have been saved to $Export`n" -ForegroundColor Green

        }

        catch {

            Write-Error -Exception $error[0].Exception.Message

        }
    }

    return $filteredResults
}

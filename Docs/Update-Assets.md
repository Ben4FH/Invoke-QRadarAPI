

## Update-Assets

* Takes a csv file containing a list of assets and their properties, and applies the values to the matching assets in Qradar.

* The first row of the CSV file must contain property names and their ID values separated by a colon (:)

* See the csv in the repository as an example.

  * Notice that not all properties need to have values, the script will just ignore them

  * QRadar will automatically set unified Name property as the value of Given Name if no value is assigned to it. 



* The API does not allow for assets to be created, only updated.

  * For this reason I recommend import the devices in the QRadar console first

  * Importing manually only allows the ip,name, weight and description

  * Once the assets exist in Qradar, you can then use this script to add extra information.

  

* Not all properties can be updated. For example, you cannot update the IP, which is why I recommend importing them with the IP first

  * For a full list of the possible properties you can update, go to /api/asset_model/properties

  * I have not been able to update the Operating System field, which is why my example csv uses the "User Supplied OS" property instead.

  * Many of these properties dont show up by default, so you should edit your asset search in QRadar to include them.



### Example Usage



**Update-Assets -File *\<path\to\asset_updates.csv\>***


![1](https://user-images.githubusercontent.com/26124323/111153752-3b314d80-858a-11eb-9f10-a903d82809aa.png)

```
PS C:\Users\Ben> Update-Assets -File .\Desktop\asset_updates.csv
Updating asset 1 out of 4...
OK
Updating asset 2 out of 4...
OK
Updating asset 3 out of 4...
OK
Updating asset 4 out of 4...
Update-Assets : NEWSERVER cannot be found in QRadar...
At line:1 char:1
+ Update-Assets -File .\Desktop\asset_updates.csv
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ObjectNotFound: (:) [Write-Error], Exception
    + FullyQualifiedErrorId : System.Exception,Update-Assets


Finished!
```
![3](https://user-images.githubusercontent.com/26124323/111153760-3cfb1100-858a-11eb-9bf0-41e585e94ad7.png)

**If the Given Name cannot be found in any of the assets in QRadar, it will be skipped...**





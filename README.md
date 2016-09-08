# MeasureLocalizedData

Control the localized keys used with Import-LocalizedData.
Retrieves the nonexistent keys and the unused keys.

Control only one file, example a module :
```Powershell
 #PowershellGet                                                                                                            
Import-Module MeasureLocalizedData
 
$Module='.\PSModule.psm1'
Measure-ImportLocalizedData -Primary $Module
```
Or multiple files, example a module with several dot sourced scripts :
```Powershell
$Module='.\Plaster.psm1'
$Functions=@(
  '.\InvokePlaster.ps1',
  '.\Measure-lasterManifest.ps1'
)

Measure-ImportLocalizedData -Primary $Module -Secondary $Functions 
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
  '.\TestPlasterManifest.ps1'
)

Measure-ImportLocalizedData -Primary $Module -Secondary $Functions
```
This call return the key nammed 'ShouldCreateNewPlasterManifest'  indicated as 'unused' :
```Powershell
ScriptName    : C:\Users\Laurent\Documents\WindowsPowerShell\Modules\Plaster\TestPlasterManifest.ps1
Keys          : {ShouldCreateNewPlasterManifest}
ResourcesFile : C:\Users\Laurent\Documents\WindowsPowerShell\Modules\Plaster\en-US\Plaster.Resources.psd1
Type          : Unused
Culture       : en-US
```
We must add all scripts :
```Powershell
$Module='.\Plaster.psm1'
$Functions=@(
  '.\InvokePlaster.ps1',
  '.\TestPlasterManifest.ps1'
  '.\NewPlasterManifest.ps1'
)

Measure-ImportLocalizedData -Primary $Module -Secondary $Functions
```
This way, the call return no error.
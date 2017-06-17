# MeasureLocalizedData

Control the localized keys used with Import-LocalizedData.
Retrieves the nonexistent keys and the unused keys.

To install this module :
```Powershell
$PSGalleryPublishUri = 'https://www.myget.org/F/ottomatt/api/v2/package'
$PSGallerySourceUri = 'https://www.myget.org/F/ottomatt/api/v2'

Register-PSRepository -Name OttoMatt -SourceLocation $PSGallerySourceUri -PublishLocation $PSGalleryPublishUri #-InstallationPolicy Trusted
Install-Module MeasureLocalizedData -Repository OttoMatt
```

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
ScriptName    : 
Keys          : {ShouldCreateNewPlasterManifest}
ResourcesFile : C:\Users\Laurent\Documents\WindowsPowerShell\Modules\Plaster\en-US\Plaster.Resources.psd1
Type          : Unused
Culture       : en-US
```
The error relates to the resource file, so the 'ScriptName' property is not specified (not applicable).

When the error relates a script this property is specified :
```Powershell
ScriptName    : C:\Users\Laurent\Documents\WindowsPowerShell\Modules\Plaster\InvokePlaster.ps1
Keys          : {NotExist_in_Ressource_File}
ResourcesFile : C:\Users\Laurent\Documents\WindowsPowerShell\Modules\Plaster\en-US\Plaster.Resources.psd1
Type          : Nonexistent
Culture       : en-US
```
To solve the case 'unused' we must add all scripts 
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


This function returns a PSObject whose PSTypeName is 'LocalizedDataDiagnostic'.
This object contains the following properties :
   * ScriptName    : Full name of the script containing the relevant keys
         
   * Keys          : Name of the relevant keys
      
   * ResourcesFile : Full Name of the localized resource file

   * Type          : Error type

                     - Unused      : Unused keys
                     - Nonexistent : unknown keys

   * Culture       : Name of culture tested
Param (
 # Specific to the development computer
 [string] $VcsPathRepository=''
) 

if (Test-Path env:APPVEYOR_BUILD_FOLDER)
{
  $VcsPathRepository=$env:APPVEYOR_BUILD_FOLDER
}

if (!(Test-Path $VcsPathRepository))
{
  Throw 'Configuration error, the variable $VcsPathRepository should be configured.'
}

# Common variable for development computers
if ( $null -eq [System.Environment]::GetEnvironmentVariable("ProfileMeasureLocalizedData","User"))
{ 
 [Environment]::SetEnvironmentVariable("ProfileMeasureLocalizedData",$VcsPathRepository, "User")
  #refresh the environment Provider
 $env:ProfileMeasureLocalizedData=$VcsPathRepository 
}

 # Specifics variables  to the development computer
$MeasureLocalizedDataDelivery= 'C:\Temp\Delivery\MeasureLocalizedData'   
$MeasureLocalizedDataLogs= 'C:\Temp\Logs\MeasureLocalizedData'
$MeasureLocalizedDataDelivery, $MeasureLocalizedDataLogs|
 Foreach {
  new-item $_ -ItemType Directory -EA SilentlyContinue         
 }
 

  # Commons variable for all development computers
 # Their content is specific to the development computer 
$MeasureLocalizedDataBin= "$VcsPathRepository\Bin"
$MeasureLocalizedDataHelp= "$VcsPathRepository\Documentation\Helps"
$MeasureLocalizedDataSetup= "$VcsPathRepository\Setup"
$MeasureLocalizedDataVcs= "$VcsPathRepository"
$MeasureLocalizedDataTests= "$VcsPathRepository\Tests"
$MeasureLocalizedDataTools= "$VcsPathRepository\Tools"
$MeasureLocalizedDataUrl='https://github.com/LaurentDardenne/MeasureLocalizedData'

 #PSDrive to the project directory 
$null=New-PsDrive -Scope Global -Name MeasureLocalizedData -PSProvider FileSystem -Root $MeasureLocalizedDataVcs 

Write-Host "Projet MeasureLocalizedData configuré." -Fore Green

rv VcsPathRepository


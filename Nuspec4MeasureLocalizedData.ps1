$ModuleVersion=(Import-ManifestData "$MeasureLocalizedDataVcs\MeasureLocalizedData.psd1").ModuleVersion
$Source='https://www.myget.org/F/ottomatt/api/v2/package'

nuspec 'MeasureLocalizedData' $ModuleVersion {

   properties @{
        Authors='Dardenne Laurent'
        Owners='Dardenne Laurent'
        title='MeasureLocalizedData module'
        Description="Module to control the use of the localization keys.The purpose is to find the nonexistent keys and the unused keys."
        summary="Module to control the use of the localization keys.."
        copyright='Copyleft'
        language='en-US'
        licenseUrl='https://creativecommons.org/licenses/by-nc-sa/4.0/'
        projectUrl='https://github.com/LaurentDardenne/MeasureLocalizedData'
        iconUrl='https://github.com/LaurentDardenne/MeasureLocalizedData/blob/master/icon/MeasureLocalizedData.png'
        releaseNotes="$(Get-Content "$MeasureLocalizedDataVcs\CHANGELOG.md" -raw)"
        tags='LocalizedData Localization Analyze'
    }
    files {
        file -src "$MeasureLocalizedDataVcs\MeasureLocalizedData.psm1"
        file -src "$MeasureLocalizedDataVcs\MeasureLocalizedData.psd1"
        file -src "$MeasureLocalizedDataVcs\README.md"
    }        
}|Foreach  { 
   $PkgName=$_.metadata.id
   $PkgVersion=$_.metadata.version
   $PathNuspec="$MeasureLocalizedDataDelivery\$PkgName.nuspec"
   
   Write-verbose "Save-Nuspec '$PathNuspec'"
   Save-Nuspec -Object $_ -FileName $PathNuspec
   
   cd $env:Temp
   nuget pack $PathNuspec
   Write-verbose "push '$env:Temp\$PkgName.$PkgVersion.nupkg'"
    #-requires : Apikey est sauvegardé sur le poste local
   nuget push "$env:Temp\$PkgName.$PkgVersion.nupkg" -Source $source
}

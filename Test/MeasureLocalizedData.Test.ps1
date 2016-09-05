$global:here = Split-Path -Parent $MyInvocation.MyCommand.Path

$M=Import-module "..\MeasureLocalizedData.psd1" -Pass 

Describe "Measure localized data" {

    Context "When there is no error" {
      It "no call to Import-LocalizedData" {
        $FileName="$here\no call to Import-LocalizedData.ps1"
        $Results =Search-ASTImportLocalizedData -Path $FileName|
                  Update-ASTLocalizedData -passthru 
        $Results | should be ($null)
      }

      It "Call to Import-LocalizedData, but no occurrence of the variable" {
        $FileName="$here\Call to Import-LocalizedData, but no occurrence of the variable.ps1"
        $Results =Search-ASTImportLocalizedData -Path $FileName|
                  Update-ASTLocalizedData -passthru 
        $Results | Should BeOfType System.Management.Automation.PSCustomObject
        $Results.FileName | should be 'Test.Resources.psd1'
        $Results.BindingVariable | should be 'Messages'
      }

      It "Call to Import-LocalizedData whith occurrence of the variable-1" {
        $FileName="$here\Call to Import-LocalizedData whith occurrence of the variable.ps1"
        $Results =Search-ASTImportLocalizedData -Path $FileName|
               Update-ASTLocalizedData -passthru 
        $Results | Should BeOfType System.Management.Automation.PSCustomObject
        $Results.FileName | should be 'Test.Resources.psd1'
        $Results.BindingVariable | should be 'Messages'
        $Results.KeysFound.Count | should be 1 
        $Results.KeysFound[0] | Should be 'Information'
      }
      
      It "Call to Import-LocalizedData whith occurrence of the variable-2" {
        $FileName="$here\Call to Import-LocalizedData whith occurrence of the variable.ps1"
        $ILD =Search-ASTImportLocalizedData -Path $FileName|
               Update-ASTLocalizedData -passthru 

        $Result=$ILD|Measure-LocalizedData -Culture 'en-US'
        $Result.Sets.Existent.Count | should be 1 
        $Result.Sets.New.Count | should be 0 
        $Result.Sets.NonExistent.Count | should be 0
      }
      
      It "Use an implicit file name" {
        $FileName="$here\Use an implicit file name.ps1"
        $Results =Search-ASTImportLocalizedData -Path $FileName
        $Results.Filename | should be 'Use an implicit file name.psd1'
      }      
      
      It "Do not use BindindVariable" {
        $FileName="$here\Do not use BindindVariable.ps1"
        $Results =Search-ASTImportLocalizedData -Path $FileName|
               Update-ASTLocalizedData -passthru 
        $Results | Should BeOfType System.Management.Automation.PSCustomObject
        $Results.FileName | should be 'Test.Resources.psd1'
        $Results.BindingVariable | should be 'Messages'
        $Results.KeysFound.Count | should be 1 
        $Results.KeysFound[0] | Should be 'Information'
      }    

      It "Do not use BindindVariable, but UICulture" {
        $FileName="$here\Do not use BindindVariable, but UICulture.ps1"
        $Results =Search-ASTImportLocalizedData -Path $FileName
        $Results.BindingVariable | should be 'Messages'
      }   
    }#context

    Context "When there are the nonexistent keys or unused keys" {
      It "Use an unknown key from the resource file" {
        $FileName="$here\Use an unknown key from the resource file.ps1"
        $ILD =Search-ASTImportLocalizedData -Path $FileName|
               Update-ASTLocalizedData -passthru 
       
        $Result=$ILD|Measure-LocalizedData -Culture 'en-US'
        $Result.Sets.Existent.Count | should be 1 
        $Result.Sets.Existent[0] | Should be 'Information'
        $Result.Sets.New.Count | should be 0 
        $Result.Sets.NonExistent.Count | should be 1
        $Result.Sets.NonExistent[0] | Should be 'Unknown_Key_In_The_Resource_File'
      }

      It "Do not use a key from the resource file" {
        $FileName="$here\Do not use a key from the resource file.ps1"
        $ILD =Search-ASTImportLocalizedData -Path $FileName|
               Update-ASTLocalizedData -passthru 
       
        $Result=$ILD|Measure-LocalizedData -Culture 'en-US'
        $Result.Sets.Existent.Count | should be 1 
        $Result.Sets.Existent[0] | Should be 'Information'
        $Result.Sets.New.Count | should be 1
        $Result.Sets.New[0] | Should be 'Key_unused_by_the_source_code' 
        $Result.Sets.NonExistent.Count | should be 0
      }
      
# Paths are calculated.ps1
      It "Paths are calculated, unsupported syntax" {
        $FileName="$here\Paths are calculated.ps1"
        $Result =Search-ASTImportLocalizedData -Path $FileName
        $Result | should be $null
      }   
    #   Test-ImportLocalizedData -Primary $Module -Secondary $Functions 

    }#context
}

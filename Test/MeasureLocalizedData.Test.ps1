$global:here = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-module "..\MeasureLocalizedData.psd1" 

Describe "Measure localized data" {

    Context "When there is no error" {
      InModuleScope MeasureLocalizedData { 
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

          $Result=$ILD|Compare-LocalizedData -Culture 'en-US'
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
      }
    }#context

    Context "When there are the nonexistent keys or unused keys" {
      InModuleScope MeasureLocalizedData { 
        It "Use an unknown key from the resource file" {
          $FileName="$here\Use an unknown key from the resource file.ps1"
          $ILD =Search-ASTImportLocalizedData -Path $FileName|
                Update-ASTLocalizedData -passthru 
        
          $Result=$ILD|Compare-LocalizedData -Culture 'en-US'
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
        
          $Result=$ILD|Compare-LocalizedData -Culture 'en-US'
          $Result.Sets.Existent.Count | should be 1 
          $Result.Sets.Existent[0] | Should be 'Information'
          $Result.Sets.New.Count | should be 1
          $Result.Sets.New[0] | Should be 'Key_unused_by_the_source_code' 
          $Result.Sets.NonExistent.Count | should be 0
        }
        
        It "Paths are calculated, unsupported syntax" {
          $FileName="$here\Paths are calculated.ps1"
          $Result =Search-ASTImportLocalizedData -Path $FileName -WarningVariable Warning -WarningAction SilentlyContinue
          $Result | should be $null
          $Warning.Count | should be 3
        }   
      }
        
      It "The primary file do not exist" {
        $FileName="$here\NotExist.ps1"
        { Measure-ImportLocalizedData -Primary $FileName } | Should Throw    
      }  

      It "The primary file contains syntax error" {
        $FileName="$here\Syntax Error.ps1"
        { Measure-ImportLocalizedData -Primary $FileName } | Should Throw    
      }  

      It "The secondary file do not exist -1 " {
        $Module="$here\Test\Plaster\Plaster.psm1"
        $Functions=@(
          "$here\Test\Plaster\nvokePlaster.ps1", # !!!
          "$here\Test\Plaster\TestPlasterManifest.ps1"
        )

        { Measure-ImportLocalizedData -Primary $Module -Secondary $Functions } | Should Throw    
      } 
      
      It "The secondary file do not exist -2" {
        $Module="$here\Test\Plaster\Plaster.psm1"
        $Functions=@(
          "$here\Test\Plaster\InvokePlaster.ps1",
          "$here\Test\Plaster\estPlasterManifest.ps1" # !!!
        )

        { Measure-ImportLocalizedData -Primary $Module -Secondary $Functions } | Should Throw    
      }  
      
      It "The culture resource file do not exist" {
        $Module="$here\Test\Plaster\Plaster.psm1"
        $Functions=@(
          "$here\Test\Plaster\InvokePlaster.ps1",
          "$here\Test\Plaster\TestPlasterManifest.ps1"
        )

        { Measure-ImportLocalizedData -Primary $Module -Secondary $Functions -culture 'de-DE' } | Should Throw       
      } 

      It "Mix up errors, unused and nonexistent" {
        $FileName="$here\MixUp.ps1"
        $Result ='en-US','fr-FR'|Measure-ImportLocalizedData -Primary $FileName
        $Result.Count | should be 4

        $Result[0].Keys.Count | should be 1
        $Result[0].Keys[0] | should be 'Unknown_Key_In_The_Resource_File'
        $Result[0].Type | should be 'Nonexistent'
        $Result[0].Culture | should be 'en-US'

        $Result[1].Keys.Count | should be 1
        $Result[1].Keys[0] | should be 'Key_unused_by_the_source_code'
        $Result[1].Type | should be 'Unused'
        $Result[1].Culture | should be 'en-US'

        $Result[2].Keys.Count | should be 3
        $Result[2].Keys[0] | should be 'Information' #Typo in 'Fr-fr' resource file
        $Result[2].Keys[1] | should be 'Unknown_Key_In_The_Resource_File'
        $Result[2].Keys[2] | should be 'Not_Exist_In_French_Resource' #this key exist only into the 'en-US' resource file
        $Result[2].Type | should be 'Nonexistent'
        $Result[2].Culture | should be 'fr-FR'

        $Result[3].Keys.Count | should be 2
        $Result[3].Keys[0] | should be 'Key_unused_by_the_source_code'
        $Result[3].Keys[1] | should be 'Informaion' #Typo
        $Result[3].Type | should be 'Unused'
        $Result[3].Culture | should be 'fr-FR'
      }  

      It "Wrong namming for FileName parameter" {
        $FileName="$here\Wrong namming for FileName parameter.ps1"
        $Error.Clear()
        Measure-ImportLocalizedData -Primary $FileName -ErrorAction SilentlyContinue
        $Error.Count | Should be 2    
      }  

      It "Wrong namming for BindingVariable parameter" {
        $FileName="$here\Wrong namming for BindingVariable parameter.ps1"
        $Error.Clear()
        Measure-ImportLocalizedData -Primary $FileName -ErrorAction SilentlyContinue
        $Error.Count | Should be 2    
      }  
      
      It "Wrong namming for BindingVariable and Filename parameters" {
        $FileName="$here\.\Wrong namming for BindingVariable and filename parameters.ps1"
        $Error.Clear()
        Measure-ImportLocalizedData -Primary $FileName -ErrorAction SilentlyContinue
        $Error.Count | Should be 3    
      }  
   }#context
}

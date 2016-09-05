#Control the use of the localization keys.
#The purpose is to find the nonexistent keys and the unused keys.

[string[]]$script:AllCultures=[System.Globalization.CultureInfo]::GetCultures('AllCultures')|Select -ExpandProperty Name
$script:Cultures=[System.Collections.Generic.HashSet[String]]::new($script:AllCultures,[StringComparer]::InvariantCulture)

function Get-LocalizedCultures {
 #Renvoi les noms de répertoire correspondant à un nom de culture
  param(
     # Chemin contenant les répertoires des ressources localisées
     #todo gestion du litteralPath
     [Parameter(Mandatory=$true)]
    [string] $BaseDirectory
  )
  foreach ($Name in Get-ChildItem -Path $BaseDirectory -Directory -Name)
  {
   if ($script:Cultures.Contains($Name))
   { $Name }  
  }
}

#todo -AsDiagnosticRecord
Function NewDiagnosticRecord{
 param ($Message,$Severity,$Ast)
  [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]::new(
    $Message,
    $Ast.Extent,
    $PSCmdlet.MyInvocation.InvocationName,
    $Severity,
    $null )
}


Function Get-AST {
#from http://becomelotr.wordpress.com/2011/12/19/powershell-vnext-ast/
<#
.Synopsis
   Function to generate AST (Abstract Syntax Tree) for PowerShell code.

.DESCRIPTION
   This function will generate Abstract Syntax Tree for PowerShell code, either from file or direct input.
   Abstract Syntax Tree is a new feature of PowerShell 3 that should make parsing PS code easier.
   Because of nature of resulting object(s) it may be hard to read (different object types are mixed in output).

.EXAMPLE
   $AST = Get-AST -FilePath MyScript.ps1
   $AST will contain syntax tree for MyScript script. Default are used for list of tokens ($Tokens) and errors ($Errors).

.EXAMPLE
   Get-AST -Input 'function Foo { param ($Foo) Write-Host $Foo }' -Tokens MyTokens -Errors MyErors | Format-Custom
   Display function's AST in Custom View. $MyTokens contain all tokens, $MyErrors would be empty (no errors should be recorded).

.INPUTS
   System.String

.OUTPUTS
   System.Management.Automation.Languagage.Ast

.NOTES
   Just concept of function to work with AST. Needs a polish and shouldn't polute Global scope in a way it does ATM.

#>

[CmdletBinding(
    DefaultParameterSetName = 'File'
)]
param (
    # Path to file to process.
    [Parameter(
        Mandatory,
        HelpMessage = 'Path to file to process',
        ParameterSetName = 'File'
    )]
    [Alias('Path','PSPath')]
    [ValidateScript({
        if (Test-Path -LiteralPath $_ -ErrorAction SilentlyContinue) {
            $true
        } else {
            throw "File does not exist!"
        }
    })]
    [string]$FilePath,
    
    # Input string to process.
    [Parameter(
        Mandatory,
        HelpMessage = 'String to process',
        ParameterSetName = 'Input'

    )]
    [Alias('Script','IS')]
    [string]$InputScript,

    # Name of the list of Errors.
    [Alias('EL')]
    [ValidateScript({$_ -ne 'ErrorsList'})] 
    [string]$ErrorsList = 'ErrorsAst',
    
    # Name of the list of Tokens.
    [Alias('TL')]
    [ValidateScript({$_ -ne 'TokensList'})]
    [string]$TokensList = 'Tokens',
    [switch] $Strict
)
     #Chaque appel de l'API crée une nouvelle instance
    New-Variable -Name $ErrorsList -Value $null -Scope Global -Force
    New-Variable -Name $TokensList -Value $null -Scope Global -Force

    switch ($psCmdlet.ParameterSetName) {
        File {
            $ParseFile = (Resolve-Path -LiteralPath $FilePath).ProviderPath
            [System.Management.Automation.Language.Parser]::ParseFile(
                $ParseFile, 
                [ref](Get-Variable -Name $TokensList),
                [ref](Get-Variable -Name $ErrorsList)
            )
        }
        Input {
            [System.Management.Automation.Language.Parser]::ParseInput(
                $InputScript, 
                [ref](Get-Variable -Name $TokensList),
                [ref](Get-Variable -Name $ErrorsList)
            )
        }
    }
   if ( (Get-Variable $ErrorsList).Value.Count -gt 0  )
   {
      $Er= New-Object System.Management.Automation.ErrorRecord(
              (New-Object System.ArgumentException("The syntax of the code is incorrect. $ParseFile")), 
              "InvalidSyntax", 
              "InvalidData",
              "[AST]"
             )  

      if ($Strict) 
      { $PSCmdlet.ThrowTerminatingError($Er)}
      else
      { $PSCmdlet.WriteError($Er)}
   }
} #Get-AST

Function Split-VariablePath {
<#
.SYNOPSIS
   Supprime l'indicateur de portée précisé dans le nom de variable          
#>            
 param (
  [System.Management.Automation.Language.VariableExpressionAst] $VEA
 )
 $VEA.VariablePath.UserPath -Replace '^(.*):(.*)$','$2'
}#Split-VariablePath

Function New-LocalizedDataInformations{
  param (
    $Path,
    [System.Management.Automation.Language.StaticBindingResult] $Binding
  )
  
  [pscustomobject]@{
      PSTypeName='LocalizedDataInformations'
        #Nom du fichier de localisation des messages 
      FileName=$binding.BoundParameters['FileName'].ConstantValue
        #Nom de la variable utilisée pour accèder aux clés de la hashtable 
        #contenant les messages localisés
      BindingVariable=$binding.BoundParameters['BindingVariable'].ConstantValue
        #Nom complet du fichier contenant les appels à Import-localizedData
        #Dénormalisation assumée ;-)
      ScriptPath=$Path      
        #Nom du fichier contenant les appels à Import-localizedData
      ScriptName=[System.IO.Path]::GetFileName($Path)
        #Nom du répertoire du fichier 
      BaseDirectory=[System.IO.Path]::GetDirectoryName($Path)
        #Liste des clés trouvées
      KeysFound=$null
  }
} #New-LocalizedDataInformations

Function Copy-LocalizedDataInformations{
  #copy des informations de localisation en modifiant 
  #le nom du path sur lequel effectuer la recherche.
  param (
      [Parameter(Position=1, Mandatory=$true,ValueFromPipeline=$true)]
    [string] $Path,

     [Parameter(Position=2, Mandatory=$true)] 
     [ValidateScript({$_.PsObject.TypeNames[0] -eq "LocalizedDataInformations"})] 
    $Item    
  )

  process {  
    $NewItem=$Item.PSObject.Copy()
    $NewItem.ScriptPath=$Path
    $NewItem.ScriptName=[System.IO.Path]::GetFileName($Path)
    $NewItem.BaseDirectory=[System.IO.Path]::GetDirectoryName($Path)
    $NewItem
  }
} #Copy-LocalizedDataInformations

Function Search-ASTImportLocalizedData {
<#
.SYNOPSIS
  Recherche dans un script les appels au cmdlet 'Import-LocalizedData'.
  On récupère le nom de la variable et le nom du fichier de localisation.
  On émet seulement les cas utilisables.
#> 

 [CmdletBinding()]
 param(
      #Chemin complet du fichier à analyser
      #contenant la déclaration d'Import-LocalizedData
     [Parameter(Position=1, Mandatory=$true)] 
   [string] $Path
 ) 

 $AstScript = Get-AST -FilePath $Path
  # 1 - Première lecture de l'arbre
  #----------Recherche les appels du cmdlet Import-LocalizedData
  #----------afin de récupèrer la valeur des paramètres 'BindingVariable' et'FileName' 
  $ImportLocalizedDataCommands = $AstScript.FindAll({
      [System.Management.Automation.Language.Ast]$ast = $args[0]
      ($ast -is [System.Management.Automation.Language.CommandAst]) -and
          (($ast.GetCommandName() -replace '.*\\(.*)$','$1') -eq 'Import-LocalizedData')
  }, $true)
  
  foreach ($Binding in $ImportLocalizedDataCommands)
  {
     $Parameters=[System.Management.Automation.Language.StaticParameterBinder]::BindCommand($Binding)
     $result=New-LocalizedDataInformations $Path $Parameters
      #Comportement du cmdlet 
     if (! $Parameters.BoundParameters.ContainsKey('FileName'))
     { $result.FileName=[System.IO.Path]::GetFileNameWithoutExtension($Path)+'.psd1' }
     elseif ($null -eq $Parameters.BoundParameters['FileName'].ConstantValue) 
     {
        #cas :  -FileName (Microsoft.PowerShell.Management\Split-Path $PSModuleInfo.Path -Leaf)       
       Write-warning "Syntax not supported : $Binding"
       Continue 
     }
     
     if (! $Parameters.BoundParameters.ContainsKey('BindingVariable'))
     {
        $astParent=$Binding.Parent.Parent
        if ($astParent -is [System.Management.Automation.Language.AssignmentStatementAst] )
        {
          if ($astParent.Left -is [System.Management.Automation.Language.VariableExpressionAst])
          {
              $result.BindingVariable=Split-VariablePath $astParent.Left
              $result 
          }
        }
     }
     else 
     { $result }
  } 
} #Search-ASTImportLocalizedData

Function Update-ASTLocalizedData {
<#
.SYNOPSIS
  Recherche dans un script les noms de clés de localisation.
  Par défaut ne renvoie aucune donnée, la fonction  modifie l'objet spécifié en entrée
#> 

 [CmdletBinding()]
 param(
     [Parameter(Position=1, Mandatory=$true,ValueFromPipeline=$true)]
     [ValidateScript({$_.PsObject.TypeNames[0] -eq "LocalizedDataInformations"})] 
   $LocalizedDatas,
   [switch] $Passthru
  ) 
process {
 $AstScript = Get-AST -FilePath $LocalizedDatas.ScriptPath
  # 2- relecture de l'arbre
  #----------Recherche les noms de clé de la hashtable précisée dans BindingVariable
  $CurrentBindingVariable= $LocalizedDatas.BindingVariable
  Write-debug "CurrentBindingVariable = $CurrentBindingVariable"     
  $Keys = $AstScript.FindAll({
    Param ($Ast)                         
      if ($ast -is [System.Management.Automation.Language.MemberExpressionAst])
      {
          #Recherche dans les membres d'expression 
          #celles dont la propriété 'Expression' est une variable, 
        if ($Ast.Expression -is [System.Management.Automation.Language.VariableExpressionAst]) 
        {
          Write-debug "MemberExpressionAst BindingVariable='$($CurrentBindingVariable)' $ast"   
          if ((Split-VariablePath $Ast.Expression) -eq $CurrentBindingVariable)  
          {$Ast}
        }
    } 
  }, $true)
  #La propriété 'Member' est le nom d'une clé de localisation
  $LocalizedDatas.KeysFound=@( $Keys.Member.Value| Select-Object -Unique )
  if ($Passthru)
  { $LocalizedDatas }
 }
} #Update-ASTLocalizedData

Function Split-SideIndicator {
<#
.SYNOPSIS
  Répartie des données issues de Compare-Object dans 3 listes.
  Renvoie un objet hébergeant ces trois listes.
#> 
 param(
       #Collection des clés à comparer
     [Parameter(Position=0, Mandatory=$true,ValueFromPipeline=$true)]
     [AllowNull()]
   [Object[]]$Inputobject 
 )
 process {
  if ($Inputobject -eq $null) {return} 
   #Clés utilisées par le code qui existent dans la hashtable 
  $Existent, 
   #Clés utilisées par le code mais inexistante dans la hashtable 
  $NonExistent, 
   #Clés de la hashtable inutilisées par le code
  $New =1..3|ForEach-Object {New-Object System.Collections.ArrayList}
  
  foreach ($Item in $InputObject)
  {
     switch ($Item.SideIndicator) 
     {
      '==' {$Existent.Add($Item.InputObject)>$null}
      '<=' {$New.Add($Item.InputObject)>$null}
      '=>' {$NonExistent.Add($Item.InputObject)>$null}
     }
  }
  [pscustomobject]@{
    PSTypeName='SideIndicator'
    Existent=$Existent
    New=$New
    NonExistent=$NonExistent
  }  
 }
}#Split-SideIndicator

Function Measure-LocalizedData {
<#
.SYNOPSIS
  Compare des données générées par la fonction Update-ASTLocalizedData.
#> 

 [CmdletBinding()]
 param(
      #Permet de pointer sur le nom du fichier de ressource
     [Parameter(Position=0, Mandatory=$true,ValueFromPipeline=$true)]
     [ValidateScript({$_.PsObject.TypeNames[0] -eq "LocalizedDataInformations"})] 
    $LocalizedDatas,

      #Précise la culture du fichier de ressource
     [Parameter(Position=1, Mandatory=$true)]
    $Culture
  ) 
process {
  Write-debug "LocalizedDatas $LocalizedDatas"
  if ($LocalizedDatas.KeysFound.Count -eq 0) 
  { 
    Write-Verbose ("No localization key found in the file :`r`n'{0}'" -f $LocalizedDatas.ScriptPath)
    return $null
  } 
    #Charge le fichier de localisation utilisée dans le code analysé.
    # Si le fichier est introuvable on arrête le traitement
    #Todo Cache simple dans la portée du module 
  Import-LocalizedData -BindingVariable HelpMsg -Filename $LocalizedDatas.FileName -UI $Culture -BaseDirectory $LocalizedDatas.BaseDirectory -EA Stop
  $Compare=Compare-Object ($HelpMsg.Keys -as [string[]]) $LocalizedDatas.KeysFound -IncludeEqual 
   #On imbrique les données pour permettre la construction d'un rapport
  [pscustomobject]@{
    PSTypeName='MeasurementLocalizedData'
    Sets=Split-Sideindicator -Inputobject $Compare
    ScriptPath=$LocalizedDatas.ScriptPath
    Culture=$Culture
    LocalizedDatas=$LocalizedDatas
   }
 }
} #Measure-LocalizedData


Function Test-ImportLocalizedData {
 param(
      #Chemin complet du fichier à analyser contenant
      #la déclaration d'Import-LocalizedData
    [Parameter(Position=1, Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
   [string] $Primary,

      #Fichiers secondaires contenant des noms de clés de localisation.
    [Parameter(Position=2, Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
   [string[]] $Secondary,

      # Permet de pointer sur le fichier d'aide associé à une ou plusieurs cultures
      # En cas d'échec, la recherche du fichier se fait dans le répertoire 
      # du $Primary.
    [Parameter(Position=3, Mandatory=$false,ValueFromPipeline=$true)] 
   [System.Globalization.CultureInfo] $Culture='en-US'

   #todo
   #[switch] $AsDiagnosticRecord

 ) 

process {
    $ILD=Search-ASTImportLocalizedData -Path $Primary|
    Foreach {
        #Emet la déclaration de Import-LocalizedData du fichier d'origine
        $_
        #Pour rechercher dans des fichiers différents  
        #On clone les mêmes clés trouvées dans le fichier primaire,
        #puis on  modifie le nom de fichier
        if ($PSBoundParameters.ContainsKey('Secondary') )
        { $Secondary|Copy-LocalizedDataInformations -Item $_ }
    }| Update-ASTLocalizedData -Passthru 


    $ofs=','
    $Result=$ILD|Measure-LocalizedData -Culture $Culture 
    #Je veux connaitre chaque fichier qui utilise des clés qui n'existent pas dans la hashtable.
    $Result|
    Foreach {
        if ($_.Sets.NonExistent.count -gt 0)
        {
            $ResourceFile="{0}\{1}\{2}" -f $_.LocalizedDatas.BaseDirectory,$_.Culture,$_.LocalizedDatas.FileName
            Write-host ("The file {0} uses keys ({1}) does not exist in the hashtable'{2}'." -f $_.LocalizedDatas.ScriptPath,"$($_.Sets.NonExistent)",$ResourceFile)
        }
    }
    
    #Je veux connaitre les clés de la hashtable qui ne sont pas utilisées
    $KeysFound=$result.LocalizedDatas.KeysFound|Select -Unique
     #une fois analysé tous les fichiers on connait toutes les clés utilisées par le code 
     #Reste à les comparer avec celles de la hashtable.
    Import-LocalizedData -BindingVariable HelpMsg -Filename $Result[-1].LocalizedDatas.FileName -UI $Result[-1].Culture -BaseDirectory $Result[-1].LocalizedDatas.BaseDirectory -EA Stop
    $Compare=compare ($HelpMsg.Keys -as [string[]]) $KeysFound 
    $Inconnues=Split-Sideindicator -Inputobject $Compare
    if ($Inconnues.New -gt 0)
    {
        $ResourceFile="{0}\{1}\{2}" -f $Result[-1].LocalizedDatas.BaseDirectory,$Result[-1].Culture,$Result[-1].LocalizedDatas.FileName
        Write-host ("The keys ({0}) declared in the file '{1}' are not used." -f "$($Inconnues.New)",$ResourceFile)
    }
 }
}#Test-ImportLocalizedData
  

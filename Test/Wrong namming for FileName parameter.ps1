# throw : Import-LocalizedData : A parameter cannot be found that matches parameter name 'Fileame'.
# Exception in  Measure-ImportLocalizedData : 
#        Import-LocalizedData : Cannot find the Windows PowerShell data file 'Wrong namming for FileName parameter.psd1'
Import-LocalizedData -BindingVariable Messages -Fileame Test.Resources.psd1 -EA Stop
Write-host $Messages.Information
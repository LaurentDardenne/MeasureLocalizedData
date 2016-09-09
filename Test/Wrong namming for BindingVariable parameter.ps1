# throw : Import-LocalizedData : A parameter cannot be found that matches parameter name 'BindinVariable'.
# Not supported by Measure-ImportLocalizedData
Import-LocalizedData -BindinVariable Messages -Filename Test.Resources.psd1 -EA Stop
Write-host $Messages.Information
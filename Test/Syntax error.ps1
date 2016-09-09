Import-LocalizedData -BindingVariable Messages -Filename Test.Resources.psd1 -EA Stop
Write-host $Messages.Information |
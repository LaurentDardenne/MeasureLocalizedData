
Import-LocalizedData -BindingVariable Message -Filename Test2.Resources.psd1 -EA Stop

function TestUnknownMsg {
 Write-host $Message.Information        
}
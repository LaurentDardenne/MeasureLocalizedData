
Import-LocalizedData -BindingVariable Message -Filename Test.Resources.psd1 -EA Stop

Write-host $Message.Information
   
function TestUnknownMsg {
 Write-host $Message.Unknown_Key_In_The_Resource_File        
}
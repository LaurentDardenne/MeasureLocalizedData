
Import-LocalizedData -BindingVariable Message -Filename Mixer.Resources.psd1 -EA Stop

Write-host $Message.Information
   
function TestUnknownMsg {
 Write-host $Message.Unknown_Key_In_The_Resource_File        
}

function TestNotExistInFrenchResource {
 Write-host $Message.Not_Exist_In_French_Resource        
}


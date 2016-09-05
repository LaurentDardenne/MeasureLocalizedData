 #Uses case : reading a module manifest
Import-LocalizedData -BindingVariable ModuleManifestHashTable `
                     -FileName (Microsoft.PowerShell.Management\Split-Path $PSModuleInfo.Path -Leaf) `
                     -BaseDirectory $PSModuleInfo.ModuleBase `
                     -ErrorAction SilentlyContinue `
                     -WarningAction SilentlyContinue

Import-LocalizedData -BindingVariable ModuleManifestHashTable `
                     -FileName (Microsoft.PowerShell.Management\Split-Path $ManifestPath -Leaf) `
                     -BaseDirectory (Microsoft.PowerShell.Management\Split-Path $ManifestPath -Parent) `
                     -ErrorAction SilentlyContinue `
                     -WarningAction SilentlyContinue                        

$MyPath= "C:\temp"
Import-LocalizedData -BindingVariable ModuleManifestHashTable `
                     -FileName $MyPath `
                     -BaseDirectory . `
                     -ErrorAction SilentlyContinue `
                     -WarningAction SilentlyContinue                        
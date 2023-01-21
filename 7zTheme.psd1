@{
	GUID = '8e92cdb5-8b74-4678-8298-76f98e6f11f1'

	ModuleVersion = '1.0'
	Description = 'ResourceLib wrapper for applying 7-zip themes'
	Author = 'Dabombber'

	RootModule = '7zTheme.psm1'
	RequiredModules = @()
	RequiredAssemblies = @(
		'ResourceLib\Vestris.ResourceLib.dll'
	)
	NestedModules = @()
	PowerShellVersion = '5.1'
	CompatiblePSEditions = @('Desktop', 'Core')

	VariablesToExport = @()
	CmdletsToExport = @()
	FunctionsToExport = @(
		'Edit-7zFiletypeIcon',
		'Edit-7zToolbarIcon',
		'Edit-7zIcon'
	)
	PrivateData = @{
		PSData = @{
			Tags = @('Theme', 'PSEdition_Desktop', 'PSEdition_Core', 'Windows')
			ReleaseNotes = @'
## 1.0
- Initial release
'@
		}
	}
}



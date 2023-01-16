<#
.SYNOPSIS

Change the icons for supported 7-zip filetypes.

.DESCRIPTION

Icons should follow the 7zTM naming convention of "extension.ico".
Multiple theme directories can be used, in which case the last available filetype icons will be applied.

.PARAMETER SevenZipPath
The path of your 7-zip installation

.PARAMETER FilePath
The path to the directory containing the filetype icon files.
#>
function Edit-7zFiletypeIcon {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
		[System.IO.DirectoryInfo] $SevenZipPath,

		[Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[Alias('PSPath', 'LP', 'LiteralPath')]
		[System.IO.DirectoryInfo[]] $FilePath
	)

	begin {
		$extensionsStringId = [UInt16]100
		$sourcePath = Join-Path -Path $SevenZipPath -ChildPath '7z.dll'
		$originalPath = Join-Path -Path $SevenZipPath -ChildPath '7z_original.dll'

		# Check 7z.dll exists
		if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
			throw "7z.dll not found in '$SevenZipPath'"
		}

		# Load resource info
		$resourceInfo = New-Object -TypeName Vestris.ResourceLib.ResourceInfo
		$resourceInfo.Load($sourcePath)
		$resourceInfo.Unload()

		# Get a list of available icons and their IconGroup
		$stringResource = $resourceInfo[([Vestris.ResourceLib.Kernel32+ResourceTypes]::RT_STRING)] | Where-Object Name -eq ([Vestris.ResourceLib.StringResource]::GetBlockId($extensionsStringId))

		# Format into a table, each group may have multiple extensions associated
		$iconList = @{}
		$stringResource.Strings[$extensionsStringId] -split '\s' | ForEach-Object {
			if ($_ -match '^(?<ext>\w+):(?<idx>\d+)$') {
				if (-not $iconList.ContainsKey($Matches.idx)) {
					$iconList[$Matches.idx] = @{Extension = New-Object System.Collections.Generic.List[string]; FilePath = $null}
				}
				$iconList[$Matches.idx].Extension.Add($Matches.ext)
			}
		}
	}

	process {
		$FilePath | ForEach-Object {
			Get-ChildItem -LiteralPath $_ -Filter '*.ico' -File | Where-Object BaseName -in $iconList.Values.Extension | ForEach-Object {
				$iconItem = $_
				$iconList.GetEnumerator() | Where-Object {$_.Value.Extension -eq $iconItem.BaseName} | ForEach-Object {
					$iconList[$_.Name].FilePath = $iconItem
				}
			}
		}
	}

	end {
		$replaceList = @{}
		$iconList.GetEnumerator() | Where-Object { $_.Value.FilePath } | ForEach-Object {
			$replaceList[$_.Key] = $_.Value
		}

		if ($replaceList.Count -eq 0) {
			Write-Warning 'No valid icons found'
		} else {
			# If there's already a backup, it should be more 'original' than the one we're modifying
			if (-not (Test-Path -LiteralPath $originalPath -PathType Leaf)) {
				Copy-Item -LiteralPath $sourcePath -Destination $originalPath
			}

			# No point working out where to put the icons in the gaps, just stick them on the end
			$iconOffset = [int]($resourceInfo[([Vestris.ResourceLib.Kernel32+ResourceTypes]::RT_ICON)].Name.Name | Where-Object {$_ -match '\d+'} | Sort-Object -Property { [int]$_ } | Select-Object -Last 1)

			# Resources to add
			$resourceList = New-Object System.Collections.Generic.List[Vestris.ResourceLib.Resource]

			$replaceList.GetEnumerator() | ForEach-Object {
				$iconName = $_.Name
				$iconFile = New-Object -TypeName Vestris.ResourceLib.IconFile -ArgumentList $_.Value.FilePath.FullName

				# Replace current icon group
				$currentIcon = $resourceInfo[([Vestris.ResourceLib.Kernel32+ResourceTypes]::RT_GROUP_ICON)] | Where-Object { $_.Name.Name -eq $iconName }

				if ($currentIcon.Count -eq 0) {
					# No current resource
					$iconDirectoryResource = New-Object -TypeName Vestris.ResourceLib.IconDirectoryResource -ArgumentList $iconFile
					$iconDirectoryResource.Name = New-Object -TypeName Vestris.ResourceLib.ResourceId -ArgumentList $iconName
					$iconDirectoryResource.Language = [Vestris.ResourceLib.ResourceUtil]::USENGLISHLANGID
					$iconDirectoryResource.Icons | ForEach-Object {
						$_.Id += $iconOffset
						$resourceList.Add($_)
					}
					$resourceList.Add($iconDirectoryResource)
				} else {
					# Use existing name/languages
					$currentIcon | ForEach-Object {
						$iconDirectoryResource = New-Object -TypeName Vestris.ResourceLib.IconDirectoryResource -ArgumentList $iconFile
						$iconDirectoryResource.Name = $_.Name
						$iconDirectoryResource.Language = $_.Language
						$iconDirectoryResource.Icons | ForEach-Object {
							$_.Id += $iconOffset
							$resourceList.Add($_)
						}
						$resourceList.Add($iconDirectoryResource)
					}
				}
				$iconOffset += $iconFile.Icons.Count
			}

			# Remove orphaned icons
			$remainingGroups = $resourceInfo[([Vestris.ResourceLib.Kernel32+ResourceTypes]::RT_GROUP_ICON)] | Where-Object { $_.Name.Name -notin $replaceList.Keys }
			$resourceInfo[([Vestris.ResourceLib.Kernel32+ResourceTypes]::RT_Icon)] | Where-Object { $_.Name.Name -notin $remainingGroups.Icons.Id } | ForEach-Object {
				$iconImageResource = New-Object -TypeName Vestris.ResourceLib.IconImageResource -ArgumentList ([Vestris.ResourceLib.Kernel32+ResourceTypes]::RT_ICON)
				$iconImageResource.Name = $_.Name
				$iconImageResource.Id = $_.Name.Id.ToInt32()
				$iconImageResource.Language = $_.Language
				$resourceList.Add($iconImageResource)
			}

			if ($resourceList.Count -gt 0) {
				[Vestris.ResourceLib.Resource]::Save($sourcePath, $resourceList)
			}
		}
	}
}

<#
.SYNOPSIS

Change the toolbar images in 7-zip.

.DESCRIPTION

The BMP images will need to be in a subfolder named based on their resolution. Currently this will be either "24x24" or "48x36".
The BMP images themselves should be named after the button they're for, these are currently:
  Add, Extract, Test, Copy, Move, Delete, Info
Multiple theme directories can be used, in which case the last available BMP images will be applied.

.PARAMETER SevenZipPath
The path of your 7-zip installation

.PARAMETER FilePath
The path to the directory containing the 24x24/48x36 BMP directories.
#>
function Edit-7zToolbarIcon {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
		[System.IO.DirectoryInfo] $SevenZipPath,

		[Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[Alias('PSPath', 'LP', 'LiteralPath')]
		[System.IO.DirectoryInfo[]] $FilePath
	)

	begin {
		# File paths
		$sourcePath = Join-Path -Path $SevenZipPath -ChildPath '7zFM.exe'
		$originalPath = Join-Path -Path $SevenZipPath -ChildPath '7zFM_original.exe'

		# Check 7zFM.exe exists
		if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
			throw "7zFM.exe not found in '$SevenZipPath'"
		}

		$toolbarIndex = @{
			  'Add' = 0
			  'Extract' = 1
			  'Test' = 2
			  'Copy' = 3
			  'Move' = 4
			  'Delete' = 5
			  'Info' = 6
		}
		$toolbarSize = @(
			@{ Width = 48; Height = 36; Offset = 100 },
			@{ Width = 24; Height = 24; Offset = 150 }
		)
		$toolbarBmp = @{}
	}

	process {
		$FilePath | ForEach-Object {
			$fp = $_
			$toolbarSize | ForEach-Object {
				$tb = $_
				$tbFolder = '{0}x{1}' -f $tb.Width, $tb.Height
				Get-ChildItem -LiteralPath $fp -Filter $tbFolder -Directory | Get-ChildItem -Filter '*.bmp' -File | Where-Object BaseName -in $toolbarIndex.Keys | ForEach-Object {
					$i = [System.Drawing.Image]::FromFile($_)
					if ($i.Width -eq $tb.Width -and $i.Height -eq $tb.Height) {
						$toolbarBmp[($tb.Offset + $toolbarIndex[$_.BaseName]).ToString()] = $_
					}
				}
			}
		}
	}

	end {
		if ($toolbarBmp.Count -eq 0) {
			Write-Warning 'No valid images found'
		} else {
			# If there's already a backup, it should be more 'original' than the one we're modifying
			if (-not (Test-Path -LiteralPath $originalPath -PathType Leaf)) {
				Copy-Item -LiteralPath $sourcePath -Destination $originalPath
			}

			$resourceInfo = New-Object -TypeName Vestris.ResourceLib.ResourceInfo
			$resourceInfo.Load($sourcePath)
			$resourceInfo.Unload()

			# Resources to add
			$resourceList = New-Object System.Collections.Generic.List[Vestris.ResourceLib.Resource]

			# Replace current images
			$resourceInfo[([Vestris.ResourceLib.Kernel32+ResourceTypes]::RT_BITMAP)] | Where-Object { $_.Name.Name -in $toolbarBmp.Keys } | ForEach-Object {
				$bitmapFile = New-Object -TypeName Vestris.ResourceLib.BitmapFile -ArgumentList $toolbarBmp[$_.Name.Name].FullName
				$bitmapResource = New-Object -TypeName Vestris.ResourceLib.BitmapResource
				$bitmapResource.Bitmap = $bitmapFile.Bitmap
				$bitmapResource.Name = $_.Name
				$bitmapResource.Language = $_.Language
				$resourceList.Add($bitmapResource)
			}

			# Add any missing images
			$toolbarBmp.GetEnumerator() | Where-Object { $_.Name -notin $resourceList.Name.Name } | ForEach-Object {
				$bitmapFile = New-Object -TypeName Vestris.ResourceLib.BitmapFile -ArgumentList $_.Value.FullName
				$bitmapResource = New-Object -TypeName Vestris.ResourceLib.BitmapResource
				$bitmapResource.Bitmap = $bitmapFile.Bitmap
				$bitmapResource.Name = New-Object -TypeName Vestris.ResourceLib.ResourceId -ArgumentList $_.Name
				#$bitmapResource..Name.Id = $_.Name
				$bitmapResource.Language = [Vestris.ResourceLib.ResourceUtil]::USENGLISHLANGID
				$resourceList.Add($bitmapResource)
			}

			if ($resourceList.Count -gt 0) {
				[Vestris.ResourceLib.Resource]::Save($sourcePath, $resourceList)
			}
		}
	}
}

<#
.SYNOPSIS

Change the icon(s) for 7-zip.

.DESCRIPTION

At least one switch should be selected for this to do anything, but multiple can be used at once if it's for the same icon.

.PARAMETER SevenZipPath
The path of your 7-zip installation

.PARAMETER FilePath
The path to the ico file.

.PARAMETER FileManagerIcon
If the File Manager icon should be replaced.

.PARAMETER GUIIcon
If the GUI icon should be replaced.

.PARAMETER PluginIcon
If the Plugin icon should be replaced (32bit and 64bit).

.PARAMETER SFXIcon
If the SFX icon should be replaced (normal and console).
#>
function Edit-7zIcon {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
		[System.IO.DirectoryInfo] $SevenZipPath,

		[Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[Alias('PSPath', 'LP', 'LiteralPath')]
		[System.IO.DirectoryInfo] $FilePath,

		[switch] $FileManagerIcon,
		[switch] $GUIIcon,
		[switch] $PluginIcon,
		[switch] $SFXIcon
	)

	begin {
		$7zIcon = @{
			FileManagerIcon = @{ FileName = '7zFM.exe'; IconGroup = '1' }
			GUIIcon = @{ FileName = '7zG.exe'; IconGroup = '1' }
			PluginIcon = @(
				@{ FileName = '7-zip.dll'; IconGroup = 'IDI_ICON' },
				@{ FileName = '7-zip32.dll'; IconGroup = 'IDI_ICON' }
			)
			SFXIcon = @(
				@{ FileName = '7z.sfx'; IconGroup = '1' },
				@{ FileName = '7zCon.sfx'; IconGroup = '101' }
			)
		}

		# Check icon exists
		$iconFile = $null
		if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
			Write-Warning "Icon not found: '$_'"
		} else {
			$iconFile = New-Object -TypeName Vestris.ResourceLib.IconFile -ArgumentList $FilePath
		}
	}

	process {
		if($iconFile) {
			$7zIcon.GetEnumerator() | ForEach-Object {
				$name = $_.Name
				if ($PSBoundParameters.$name) {
					$_.Value | ForEach-Object {
						$sourcePath = Join-Path -Path $SevenZipPath -ChildPath $_.FileName
						if ($_.FileName.Contains('.')) {
							$originalPath = Join-Path -Path $SevenZipPath -ChildPath ($_.FileName -replace '\.([^.]*)$', '_original.$1')
						} else {
							$originalPath = Join-Path -Path $SevenZipPath -ChildPath ($_.FileName + '_original')
						}

						if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
							throw "$name not found in '$sourcePath'"
						} else {
							# If there's already a backup, it should be more 'original' than the one we're modifying
							if (-not (Test-Path -LiteralPath $originalPath -PathType Leaf)) {
								Copy-Item -LiteralPath $sourcePath -Destination $originalPath
							}

							# Load resource info
							$resourceInfo = New-Object -TypeName Vestris.ResourceLib.ResourceInfo
							$resourceInfo.Load($sourcePath)
							$resourceInfo.Unload()

							# No point working out where to put the icons in the gaps, just stick them on the end
							$iconOffset = [int]($resourceInfo[([Vestris.ResourceLib.Kernel32+ResourceTypes]::RT_ICON)].Name.Name | Where-Object {$_ -match '\d+'} | Sort-Object -Property { [int]$_ } | Select-Object -Last 1)
							$iconName = $_.IconGroup

							# Resources to add
							$resourceList = New-Object System.Collections.Generic.List[Vestris.ResourceLib.Resource]

							# Replace current icon group
							$currentIcon = $resourceInfo[([Vestris.ResourceLib.Kernel32+ResourceTypes]::RT_GROUP_ICON)] | Where-Object { $_.Name.Name -eq $iconName }

							if ($currentIcon.Count -eq 0) {
								# No current resource
								$iconDirectoryResource = New-Object -TypeName Vestris.ResourceLib.IconDirectoryResource -ArgumentList $iconFile
								$iconDirectoryResource.Name = New-Object -TypeName Vestris.ResourceLib.ResourceId -ArgumentList $iconName
								$iconDirectoryResource.Language = [Vestris.ResourceLib.ResourceUtil]::USENGLISHLANGID
								$iconDirectoryResource.Icons | ForEach-Object {
									$_.Id += $iconOffset
									$resourceList.Add($_)
								}
								$resourceList.Add($iconDirectoryResource)
							} else {
								# Use existing name/languages
								$currentIcon | ForEach-Object {
									$iconDirectoryResource = New-Object -TypeName Vestris.ResourceLib.IconDirectoryResource -ArgumentList $iconFile
									$iconDirectoryResource.Name = $_.Name
									$iconDirectoryResource.Language = $_.Language
									$iconDirectoryResource.Icons | ForEach-Object {
										$_.Id += $iconOffset
										$resourceList.Add($_)
									}
									$resourceList.Add($iconDirectoryResource)
								}
							}

							# Remove orphaned icons
							$remainingGroups = $resourceInfo[([Vestris.ResourceLib.Kernel32+ResourceTypes]::RT_GROUP_ICON)] | Where-Object { $_.Name.Name -ne $iconName }
							$resourceInfo[([Vestris.ResourceLib.Kernel32+ResourceTypes]::RT_Icon)] | Where-Object { $_.Name.Name -notin $remainingGroups.Icons.Id } | ForEach-Object {
								$iconImageResource = New-Object -TypeName Vestris.ResourceLib.IconImageResource -ArgumentList ([Vestris.ResourceLib.Kernel32+ResourceTypes]::RT_ICON)
								$iconImageResource.Name = $_.Name
								$iconImageResource.Id = $_.Name.Id.ToInt32()
								$iconImageResource.Language = $_.Language
								$resourceList.Add($iconImageResource)
							}

							if ($resourceList.Count -gt 0) {
								[Vestris.ResourceLib.Resource]::Save($sourcePath, $resourceList)
							}
						}
					}
				}
			}
		}
	}

	end {}
}

Export-ModuleMember -Function 'Edit-7zFiletypeIcon', 'Edit-7zToolbarIcon', 'Edit-7zIcon'

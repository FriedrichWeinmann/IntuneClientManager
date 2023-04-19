function Get-IcmInventory {
	[CmdletBinding()]
	param (
		[string[]]
		$ComputerName,

		[PSCredential]
		$Credential
	)

	begin {
		$code = {
			foreach ($node in Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Inventories') {
				$properties = Get-ItemProperty -Path $node.PSPath

				[PSCustomObject]@{
					PSTypeName   = 'IntuneClientManager.Inventory.Software'
					Name         = $properties.Name
					Version      = $properties.Version
					InstallDate  = $properties.InstallDate
					ID           = $node.PSChildName
					ComputerName = $env:COMPUTERNAME
				}
			}
		}
	}
	process {
		$param = @{
			ScriptBlock = $code
		}
		if ($ComputerName) { $param.ComputerName = $ComputerName }
		if ($Credential) { $param.Credential = $Credential }

		Invoke-Command @param	
	}
}
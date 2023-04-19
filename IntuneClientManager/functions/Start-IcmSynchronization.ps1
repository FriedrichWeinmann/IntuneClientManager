function Start-IcmSynchronization
{
	[CmdletBinding()]
	param (
		[string[]]
		$ComputerName,

		[PSCredential]
		$Credential
	)

	begin {
		$code = {
			Get-ScheduledTask "Schedule to run OMADMClient by client" | Start-ScheduledTask
			Get-ScheduledTask "Schedule #3 created by enrollment client" | Start-ScheduledTask
			Get-Service "IntuneManagementExtension" | Restart-Service
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
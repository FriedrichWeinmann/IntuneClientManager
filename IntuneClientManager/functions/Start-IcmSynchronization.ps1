function Start-IcmSynchronization {
	[CmdletBinding()]
	param (
		[string[]]
		$ComputerName,

		[PSCredential]
		$Credential,

		[switch]
		$Wait
	)

	begin {
		$code = {
			param ( $Wait )
			Get-ScheduledTask | Where-Object TaskName -EQ 'PushLaunch' | Start-ScheduledTask
			if (-not $Wait) { return }
			
			while ((Get-ScheduledTask | Where-Object TaskName -EQ 'PushLaunch').State -ne 'Ready') {
				Start-Sleep -Seconds 1
			}
		}
	}
	process {
		$param = @{
			ScriptBlock = $code
			ArgumentList = $Wait
		}
		if ($ComputerName) { $param.ComputerName = $ComputerName }
		if ($Credential) { $param.Credential = $Credential }

		Invoke-Command @param	
	}
}
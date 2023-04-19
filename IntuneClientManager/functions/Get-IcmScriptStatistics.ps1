function Get-IcmScriptStatistics {
	[CmdletBinding()]
	param (
		[string[]]
		$ComputerName,

		[PSCredential]
		$Credential
	)

	begin {
		$code = {
			$results = @{ }
			foreach ($mainNode in Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\SideCarPolicies\Scripts\Execution') {
				switch ($mainNode.PSChildName) {
					'00000000-0000-0000-0000-000000000000' {
						$scope = $env:COMPUTERNAME
					}
					default {
						$scope = Resolve-UserID -ID $mainNode.PSChildName
					}
				}
				foreach ($node in Get-ChildItem $mainNode.PSPath) {
					$lastExecution = [Datetime]::ParseExact((Get-ItemProperty -Path $node.PSPath).LastExecution, 'dd/MM/yyyy HH:mm:ss', $null)
					$results["$($mainNode.PSChildName):$($node.PSChildName -replace '_.+')"] = @{
						PSTypeName    = 'IntuneClientManager.Statistics.Script'
						ComputerName  = $env:COMPUTERNAME
						ScopeID       = $mainNode.PSChildName
						Scope         = $scope
						ID            = $node.PSChildName -replace '_.+'
						Version       = $node.PSChildName -replace '.+_'
						LastExecution = $lastExecution
						HasPSError    = $false
					}
				}
			}
			foreach ($mainNode in Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\SideCarPolicies\Scripts\Reports') {
				foreach ($node in Get-ChildItem $mainNode.PSPath) {
					$identity = "$($mainNode.PSChildName):$($node.PSChildName -replace '_.+')"

					if (-not $results[$identity]) {
						switch ($mainNode.PSChildName) {
							'00000000-0000-0000-0000-000000000000' {
								$scope = $env:COMPUTERNAME
							}
							default {
								$scope = Resolve-UserID -ID $mainNode.PSChildName
							}
						}
						$results[$identity] = @{
							PSTypeName    = 'IntuneClientManager.Statistics.Script'
							ComputerName  = $env:COMPUTERNAME
							ScopeID       = $mainNode.PSChildName
							Scope         = $scope
							ID            = $node.PSChildName -replace '_.+'
							Version       = $node.PSChildName -replace '.+_'
							LastExecution = $null
							HasPSError    = $false
						}
					}

					$result = Get-ItemProperty -Path (Join-Path $node.PSPath 'Result')
					$results[$identity].RawResult = $result.Result
					try { $results[$identity].Result = $result.Result | ConvertFrom-Json }
					catch { $results[$identity].Result = "Error: $_" }
				}
			}

			foreach ($entry in $results.Values) {
				if (
					$entry.Result.PreRemediationDetectScriptError -or
					$entry.Result.RemediationScriptErrorDetails -or
					$entry.Result.PostRemediationDetectScriptError
				) { $entry.HasPSError = $true }
				[PSCustomObject]$entry
			}
		}
	}
	process {
		$param = @{
			ScriptBlock = Add-ScriptCommand -ScriptBlock $code -Command Resolve-UserID
		}
		if ($ComputerName) { $param.ComputerName = $ComputerName }
		if ($Credential) { $param.Credential = $Credential }

		Invoke-Command @param
	}
}
function Resolve-UserID {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[guid]
		$ID
	)

	if (-not $script:identities) {
		$script:identities = @{ }
	}

	$idstring = $ID -as [string]
	if ($script:identities[$idstring]) {
		return $script:identities[$idstring]
	}

	$prop = Get-ItemProperty -Path 'Registry::HKEY_USERS\*\Software\Microsoft\Office\*\Common\Identity' | Where-Object ConnectedOneAuthAccountId -EQ $idstring | Select-Object -Last 1
	if ($prop.ADUserName) {
		$script:identities[$idstring] = $prop.ADUserName
		$prop.ADUserName
		return
	}

	$script:identities[$idstring] = $idstring
	$script:identities[$idstring]
}
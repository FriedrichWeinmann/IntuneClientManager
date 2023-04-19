function Add-ScriptCommand {
	[OutputType([scriptblock])]
	[CmdletBinding()]
	param (
		[scriptblock]
		$ScriptBlock,

		[string[]]
		$Command
	)

	$definitions = foreach ($cmdName in $Command) {
		@'
function {0} {{
{1}
}}
'@ -f $cmdName, (Get-Command $cmdName).Definition
	}

	if (-not $ScriptBlock.Ast.ParamBlock) {
		$newCode = @($definitions) + @($ScriptBlock.ToString()) -join "`n`n"
		return [scriptblock]::Create($newCode)
	}

	$lines = $ScriptBlock.Ast.Extent.Text-split "`n"
	$paramText = $lines[0..($ScriptBlock.Ast.ParamBlock.Extent.EndLineNumber - 1)] -join "`n"
	$bodyText = $lines[$ScriptBlock.Ast.ParamBlock.Extent.EndLineNumber..($lines.Count)] -join "`n"

	$newCode = @($paramText) + @($definitions) + @($bodyText) -join "`n`n"
	if ($newCode.StartsWith('{')) {
		$newCode = $newCode.TrimStart('{').TrimEnd('}')
	}
	[scriptblock]::Create($newCode)
}
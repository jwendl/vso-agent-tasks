[CmdletBinding()]
param([switch]$OmitDotSource)

Trace-VstsEnteringInvocation $MyInvocation
[string]$MSBuildLocationMethod = Get-VstsInput -Name 'MSBuildLocationMethod'
[string]$MSBuildLocation = Get-VstsInput -Name 'MSBuildLocation'
[string]$MSBuildArguments = Get-VstsInput -Name 'MSBuildArguments'
[string]$Solution = Get-VstsInput -Name 'Solution' -Require
[string]$Platform = Get-VstsInput -Name 'Platform'
[string]$Configuration = Get-VstsInput -Name 'Configuration'
[bool]$Clean = Get-VstsInput -Name 'Clean' -AsBool
[bool]$RestoreNuGetPackages = Get-VstsInput 'RestoreNuGetPackages' -AsBool
[bool]$LogProjectEvents = Get-VstsInput -Name 'LogProjectEvents' -AsBool
[string]$MSBuildVersion = Get-VstsInput -Name 'MSBuildVersion'
[string]$MSBuildArchitecture = Get-VstsInput -Name 'MSBuildArchitecture'
if (!$OmitDotSource) {
    . $PSScriptRoot\Helpers_PSExe.ps1
}

$solutionFiles = Get-SolutionFiles -Solution $Solution
$MSBuildArguments = Format-MSBuildArguments -MSBuildArguments $MSBuildArguments -Platform $Platform -Configuration $Configuration
$MSBuildLocation = Select-MSBuildLocation -Method $MSBuildLocationMethod -Location $MSBuildLocation -Version $MSBuildVersion -Architecture $MSBuildArchitecture
Invoke-BuildTools -NuGetRestore:$RestoreNuGetPackages -SolutionFiles $solutionFiles -MSBuildLocation $MSBuildLocation -MSBuildArguments $MSBuildArguments -Clean:$Clean -NoTimelineLogger:(!$LogProjectEvents)
Trace-VstsLeavingInvocation $MyInvocation
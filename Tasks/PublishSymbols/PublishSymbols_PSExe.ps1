[CmdletBinding()]
param([switch]$OmitDotSource)

Trace-VstsEnteringInvocation $MyInvocation
[string]$SymbolsPath = Get-VstsInput -Name 'SymbolsPath'
[string]$SearchPattern = Get-VstsInput -Name 'SearchPattern' -Default "**\bin\**\*.pdb"
if ([string]$SourceFolder = (Get-VstsInput -Name 'SourceFolder') -and
    $SourceFolder -ne (Get-VstsVariable -Name 'Build.SourcesDirectory' -Require)) {
    Write-Warning (Get-LocString -Key 'SourceFolderParameterDeprecatedIgnoring0' -ArgumentList $SourceFolder)
}

[string]$SymbolsProduct = Get-VstsInput -Name 'SymbolsProduct' -Default (Get-VstsVariable -Name 'Build.DefinitionName' -Require)
[string]$SymbolsVersion = Get-VstsInput -Name 'SymbolsVersion' -Default (Get-VstsVariable -Name 'Build.BuildNumber' -Require)
[int]$SymbolsMaximumWaitTime = Get-VstsInput -Name 'SymbolsMaximumWaitTime' -Default '0' -AsInt
[string]$SymbolsFolder = Get-VstsInput -Name 'SymbolsFolder' -Default (Get-VstsVariable -Name 'Build.SourcesDirectory' -Require)
[string]$SymbolsArtifactName = Get-VstsInput -Name 'SymbolsArtifactName'
[bool]$TreatNotIndexedAsWarning = Get-VstsInput -Name 'TreatNotIndexedAsWarning' -AsBool
if (!$OmitDotSource) {
    . $PSScriptRoot\Helpers.ps1
}

# Default max wait time.
$maxWaitTime = if ($SymbolsMaximumWaitTime -gt 0) { [timespan]::FromMinutes($SymbolsMaximumWaitTime) } else { [timespan]::FromHours(2) }
Write-Verbose "Max wait time: $maxWaitTime"

# Default maxSemaphoreAge.
$maxSemaphoreAge = [timespan]::FromDays(1)
Write-Verbose "Max semaphore age: $maxSemaphoreAge"

# Get the PDB file paths.
$pdbFiles = @(Find-VstsFiles -LiteralDirectory $SymbolsFolder -SearchPattern $LegacySearchPattern)
Write-Host (Get-LocString -Key "Found0SymbolFilesToIndex" -ArgumentList $pdbFiles.Count)

# Index the sources.
Invoke-IndexSources -SymbolsFilePaths $pdbFiles -TreatNotIndexedAsWarning:$TreatNotIndexedAsWarning

# Publish the symbols.
if ($SymbolsPath) {
    $utcNow = (Get-Date).ToUniversalTime()
    $semaphoreMessage = "Machine: $env:ComputerName, BuildUri: $env:Build_BuildUri, BuildNumber: $env:Build_BuildNumber, RepositoryName: $env:Build_Repository_Name, RepositoryUri: $env:Build_Repository_Uri, Team Project: $env:System_TeamProject, CollectionUri: $env:System_TeamFoundationCollectionUri at $utcNow UTC"
    Invoke-PublishSymbols -PdbFiles $pdbFiles -Share $SymbolsPath -Product $SymbolsProduct -Version $SymbolsVersion -MaximumWaitTime $maxWaitTime.TotalMilliseconds -MaximumSemaphoreAge $maxSemaphoreAge.TotalMinutes -ArtifactName $SymbolsArtifactName -SemaphoreMessage $semaphoreMessage
} else {
    Write-Verbose "SymbolsPath was not set, publish symbols step was skipped."
}

Trace-VstsLeavingInvocation $MyInvocation

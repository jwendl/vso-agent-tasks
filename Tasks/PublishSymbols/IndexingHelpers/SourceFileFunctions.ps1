function Get-SourceFilePaths {
    [CmdletBinding()]
    param(
        [string]$SymbolsFilePath = $(throw 'Missing SymbolsFilePath'),
        [string]$SourcesRootPath = $(throw 'Missing SourcesRootPath'),
        [switch]$TreatNotIndexedAsWarning
    )

    Trace-VstsEnteringInvocation $MyInvocation
    Assert-VstsPath -LiteralPath $SymbolsFilePath -PathType Leaf # Validate the symbols file exists.

    # Get the referenced source file paths.
    $sourceFilePaths = @(Get-DbghelpSourceFilePaths -SymbolsFilePath $SymbolsFilePath)
    if (!$sourceFilePaths.Count) {
        # Warn if no source file paths were contained in the PDB file.
        [string]$message = Get-VstsLocString -Key 'UnableToIndexSourcesForSymbolsFile0DoesNotContainSourceFiles.' -ArgumentList $SymbolsFilePath
        if ($TreatNotIndexedAsWarning) {
            Write-Warning $message
        } else {
            Write-Host $message
        }

        return
    }

    # Make the sources root path end with a trailing slash.
    $SourcesRootPath = $SourcesRootPath.TrimEnd('\')
    $SourcesRootPath = "$SourcesRootPath\"

    [bool]$isPreambleWritten = $false
    foreach ($sourceFilePath in $sourceFilePaths) {
        # Trim the source file path.
        $sourceFilePath = $sourceFilePath.Trim()

        # Check whether the source file is under sources root.
        [bool]$isUnderSourcesRoot = $sourceFilePath.StartsWith(
            $SourcesRootPath,
            [System.StringComparison]::OrdinalIgnoreCase)

        # Check whether the source file exists.
        [bool]$isFound = $isUnderSourcesRoot -and (Test-Path -LiteralPath $sourceFilePath -PathType Leaf)

        # Warn if issues.
        if (!$isUnderSourcesRoot -or !$isFound) {
            # Write the warning preamble if not already written once.
            if (!$isPreambleWritten) {
                [string]$message = Get-VstsLocString -Key 'UnableToIndexOneOrMoreSourceFilesForSymbolsFile0' -ArgumentList $SymbolsFilePath
                if ($TreatNotIndexedAsWarning) {
                    Write-Warning $message
                } else  {
                    Write-Host $message
                }
            }

            # Set the flag indicating that the preamble warning has been printed.
            $isPreambleWritten = $true

            if (!$isUnderSourcesRoot) {
                # Warn that the source file path is not under the sources root.
                [string]$message = Get-VstsLocString -Key 'SourceFileNotUnderSourcesRootSourceFile0SourcesRootDirectory1' -ArgumentList $sourceFilePath, $SourcesRootPath
                if ($TreatNotIndexedAsWarning) {
                    Write-Warning $message
                } else {
                    Write-Host $message
                }
            } elseif (!$isFound) {
                # Warn that the source file does not exist.
                [string]$message = Get-VstsLocString -Key 'SourceFileNotFound0' -ArgumentList $sourceFilePath
                if ($TreatNotIndexedAsWarning) {
                    Write-Warning $message
                } else {
                    Write-Host $message
                }
            } else {
                throw 'Not supported' # Execution should never reach here.
            }

            # Prevent the source file path from being output.
            continue
        }

        # Output the source file path.
        $sourceFilePath
    }

    Trace-VstsLeavingInvocation $MyInvocation
}

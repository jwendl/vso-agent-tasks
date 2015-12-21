function Add-SourceServerStream {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PdbStrPath,

        [Parameter(Mandatory = $true)]
        [string]$SymbolsFilePath,

        [Parameter(Mandatory = $true)]
        [string]$StreamContent
    )

    # Create a temp file to store the stream content.
    Write-Verbose "Writing source server stream content to a temp file."
    $streamContentFilePath = Get-TempFileName
    try {
        # For encoding consistency with previous implementation, use File.WriteAllText(...) instead
        # of Out-File. From ildasm, it appears WriteAllText uses UTF8 with no BOM. It's impossible
        # to use the no-BOM UTF8 encoding with Set-Content or Out-File. Therefore, in order to be
        # able to stub out the call, created a small wrapper function instead.
        Write-AllText -Path $streamContentFilePath -Content $StreamContent
        Write-Verbose "Wrote stream content to: $streamContentFilePath"

        # Store the original symbols file path.
        [string]$originalSymbolsFilePath = $SymbolsFilePath
        try {
            # Pdbstr.exe doesn't work with symbols files with a space in the path. If the symbols file
            # has a space in file path, then pdbstr.exe just prints the command usage information over
            # STDOUT. It doesn't inject the indexing info into the PDB file, doesn't write to STDERR,
            # and doesn't return a non-zero exit code.
            if ($SymbolsFilePath.Contains(' ')) {
                # Create a temp file.
                Write-Verbose "Symbols file path contains a space. Copying to a temp file."
                $SymbolsFilePath = Get-TempFileName

                # If the temp file contains a space in the path, then the Invoke-IndexSources function
                # would have already printed a warning. No need to check and warn again here.

                # Copy the original symbols file over the temp file.
                Copy-Item -LiteralPath $originalSymbolsFilePath -Destination $SymbolsFilePath
                Write-Verbose "Copied symbols file to: $SymbolsFilePath"
            }

            # Invoke pdbstr.exe.
            Invoke-VstsTool -FileName $PdbStrPath -Arguments "-w -p:""$SymbolsFilePath"" -i:""$streamContentFilePath"" -s:srcsrv" 2>&1 |
                ForEach-Object {
                    if ($_ -is [System.Management.Automation.ErrorRecord]) {
                        Write-Error -ErrorRecord $_
                    } else {
                        Write-Verbose $_
                    }
                }

            # Copy the temp symbols file back over the original file.
            if ($SymbolsFilePath -ne $originalSymbolsFilePath) {
                Write-Verbose "Copying over the original symbols file from the temp file. Copy source: $SymbolsFilePath ; Copy target: $originalSymbolsFilePath"
                Copy-Item -LiteralPath $SymbolsFilePath -Destination $originalSymbolsFilePath
            }
        } finally {
            # Clean up the temp symbols file.
            if ($SymbolsFilePath -ne $originalSymbolsFilePath) {
                Write-Verbose "Deleting temp symbols file."
                Remove-Item -LiteralPath $SymbolsFilePath
            }
        }
    } finally {
        # Clean up the temp stream content file.
        Write-Verbose "Deleting temp source server stream content file."
        Remove-Item -LiteralPath $streamContentFilePath
    }
}

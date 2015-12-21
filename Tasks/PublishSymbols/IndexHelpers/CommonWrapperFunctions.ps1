function Get-CurrentProcess {
    [CmdletBinding()]
    param()

    [System.Diagnostics.Process]::GetCurrentProcess()
}

function Get-LastWin32Error {
    [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
}

function Get-TempFileName {
    [System.IO.Path]::GetTempFileName()
}

function Write-AllText {
    [CmdletBinding()]
    param([string]$Path, [string]$Content)

    [System.IO.File]::WriteAllText($Path, $Content)
}

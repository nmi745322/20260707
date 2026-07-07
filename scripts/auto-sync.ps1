$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$git = 'C:\Users\조민환\scoop\shims\git.exe'
$paths = @(
    (Join-Path $repoRoot 'index.html'),
    (Join-Path $repoRoot 'DESIGN.md')
)

function Write-Log {
    param([string]$Message)
    $stamp = Get-Date -Format 'HH:mm:ss'
    Write-Host "[$stamp] $Message"
}

function Get-Stamp {
    ($paths | ForEach-Object {
        if (Test-Path $_) {
            (Get-Item $_).LastWriteTimeUtc.Ticks.ToString()
        } else {
            'missing'
        }
    }) -join '|'
}

function Sync-Repo {
    $status = & $git status --porcelain
    if (-not $status) {
        return
    }

    & $git add index.html DESIGN.md | Out-Null

    $commitMessage = "Auto sync lotto site $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    & $git commit -m $commitMessage | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Log 'Commit skipped or failed.'
        return
    }

    & $git push origin main
    if ($LASTEXITCODE -eq 0) {
        Write-Log 'Pushed to GitHub.'
    } else {
        Write-Log 'Push failed.'
    }
}

$lastStamp = Get-Stamp
Write-Log 'Auto-sync watcher is running.'
Write-Log 'Editing index.html or DESIGN.md will trigger commit + push.'

while ($true) {
    Start-Sleep -Seconds 2
    $currentStamp = Get-Stamp
    if ($currentStamp -ne $lastStamp) {
        Start-Sleep -Seconds 2
        Sync-Repo
        $lastStamp = Get-Stamp
    }
}

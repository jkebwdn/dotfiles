param(
    [ValidateSet("Save", "Restore", "Status")]
    [string]$Action = "Status",

    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

$repo = $PSScriptRoot
$gitRoot = (Resolve-Path (Join-Path $repo "..\..")).Path
$live = Join-Path $HOME ".config"

$files = [ordered]@{
    "Komorebi\komorebi.json"                 = "komorebi\komorebi.json"
    "Komorebi\komorebi.bar.json"             = "komorebi\komorebi.bar.json"
    "whkd\whkdrc"                            = "whkd\whkdrc"
    "Fastfetch\config.jsonc"                 = "fastfetch\config.jsonc"
    "Starship\starship.toml"                 = "starship.toml"
    "PowerShell\profile.ps1"                 = "powershell\profile.ps1"
    "PowerShell\start-rice.ps1"              = "powershell\start-rice.ps1"
    "Flow-Launcher\Black Metal Khold.xaml"   = "flow-launcher\Black Metal Khold.xaml"
}

$terminalLive = Join-Path $env:LOCALAPPDATA `
    "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

$terminalRepo = Join-Path $repo "WindowsTerminal\settings.json"
function Copy-Config {
    param(
        [string]$Source,
        [string]$Destination
    )

    $directory = Split-Path $Destination -Parent
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

switch ($Action) {
    "Status" {
        git -C $gitRoot status --short --branch
    }

    "Save" {
        foreach ($entry in $files.GetEnumerator()) {
            $source = Join-Path $live $entry.Value
            $destination = Join-Path $repo $entry.Key

            if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
                throw "Missing live configuration: $source"
            }

            if ($WhatIf) {
                Write-Host "Would save: $($entry.Key)"
                continue
            }

            Copy-Config -Source $source -Destination $destination

            # Normalise repository copy: LF and one final newline
            $saved = [System.IO.File]::ReadAllText($destination)
            $saved = $saved -replace "`r`n?", "`n"
            $saved = $saved.TrimEnd("`r", "`n") + "`n"

            [System.IO.File]::WriteAllText(
                $destination,
                $saved,
                [System.Text.UTF8Encoding]::new($false)
            )

            Write-Host "Saved: $($entry.Key)" -ForegroundColor Green
        }

        if (-not (Test-Path -LiteralPath $terminalLive -PathType Leaf)) {
            throw "Missing Windows Terminal settings: $terminalLive"
        }

        if ($WhatIf) {
            Write-Host "Would save: WindowsTerminal\settings.json"
        }
        else {
            Copy-Config -Source $terminalLive -Destination $terminalRepo

            $terminalSettings = Get-Content $terminalRepo -Raw |
                ConvertFrom-Json

            $pwsh = $terminalSettings.profiles.list |
                Where-Object { $_.name -eq "PowerShell" } |
                Select-Object -First 1

            if ($pwsh) {
                $pwsh.commandline = "pwsh.exe -NoLogo"
            }

            $json = $terminalSettings | ConvertTo-Json -Depth 100
            $json = ($json -replace "`r`n?", "`n").TrimEnd("`r", "`n") + "`n"

            [System.IO.File]::WriteAllText(
                $terminalRepo,
                $json,
                [System.Text.UTF8Encoding]::new($false)
            )

            Write-Host "Saved: WindowsTerminal\settings.json" -ForegroundColor Green
        }
        if (-not $WhatIf) {
            $config = Join-Path $repo "Komorebi\komorebi.json"
            $json = Get-Content $config -Raw | ConvertFrom-Json
            $json.app_specific_configuration_path =
                '$Env:USERPROFILE/.config/komorebi/applications.json'

            $json | ConvertTo-Json -Depth 50 |
                Set-Content $config -Encoding utf8
        }
    }

    "Restore" {
        $rules = Join-Path $live "komorebi\applications.json"

        if (-not (Test-Path -LiteralPath $rules -PathType Leaf)) {
            throw "Missing Komorebi application rules: $rules"
        }

        # Validate all sources before changing any files
        foreach ($entry in $files.GetEnumerator()) {
            $source = Join-Path $repo $entry.Key
            if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
                throw "Missing repository configuration: $source"
            }
        }

        if (-not (Test-Path -LiteralPath $terminalRepo -PathType Leaf)) {
            throw "Missing Windows Terminal repository settings: $terminalRepo"
        }
        $themeSource = Join-Path $repo "Flow-Launcher\Black Metal Khold.xaml"
        $themeLive = Join-Path $HOME (
            "scoop\persist\flow-launcher\UserData\Themes\Black Metal Khold.xaml"
        )

        $backupRoot = Join-Path $HOME (
            "dotfiles-backups\Dell-Precision-7560\" +
            (Get-Date -Format "yyyyMMdd-HHmmss")
        )

        $restoreItems = @(
            foreach ($entry in $files.GetEnumerator()) {
                [PSCustomObject]@{
                    Source = Join-Path $repo $entry.Key
                    Destination = Join-Path $live $entry.Value
                    RelativePath = $entry.Value
                }
            }
        )

        $restoreItems += [PSCustomObject]@{
            Source = $themeSource
            Destination = $themeLive
            RelativePath = "flow-launcher\active-theme\Black Metal Khold.xaml"
        }

        $restoreItems += [PSCustomObject]@{
            Source = $terminalRepo
            Destination = $terminalLive
            RelativePath = "windows-terminal\settings.json"
        }
        foreach ($item in $restoreItems) {
            if ($WhatIf) {
                Write-Host "Would restore: $($item.Destination)"
                continue
            }

            if (Test-Path -LiteralPath $item.Destination) {
                $backup = Join-Path $backupRoot $item.RelativePath
                Copy-Config -Source $item.Destination -Destination $backup
            }

            Copy-Config -Source $item.Source -Destination $item.Destination
            Write-Host "Restored: $($item.Destination)" -ForegroundColor Green
        }

        if (-not $WhatIf) {
            $config = Join-Path $live "komorebi\komorebi.json"
            $json = Get-Content $config -Raw | ConvertFrom-Json
            $json.app_specific_configuration_path =
                $rules.Replace('\', '/')

            $json | ConvertTo-Json -Depth 50 |
                Set-Content $config -Encoding utf8

            Write-Host "Backups: $backupRoot" -ForegroundColor Cyan
        }
    }
}

# Black Metal — PowerShell configuration

function rice {
    & "$HOME\.config\powershell\start-rice.ps1"
}

# =========================================================
# Starship — Black Metal Prompt
# =========================================================

$env:STARSHIP_CONFIG = Join-Path $HOME ".config\starship.toml"

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
}

# =========================================================
# Fastfetch — Startup System Information
# =========================================================

# Only display in interactive terminal sessions
if (
    [Environment]::UserInteractive -and
    $Host.Name -eq "ConsoleHost" -and
    (Get-Command fastfetch -ErrorAction SilentlyContinue)
) {
    & fastfetch --config "$HOME\.config\fastfetch\config.jsonc"
}

# =========================================================
# Black Metal — Dotfiles
# =========================================================

function rice-save {
    & "$HOME\dotfiles\Windows\Dell-Precision-7560\sync.ps1" -Action Save
}

function rice-status {
    & "$HOME\dotfiles\Windows\Dell-Precision-7560\sync.ps1" -Action Status
}

function rice-restore {
    param([switch]$WhatIf)

    & "$HOME\dotfiles\Windows\Dell-Precision-7560\sync.ps1" `
        -Action Restore -WhatIf:$WhatIf
}

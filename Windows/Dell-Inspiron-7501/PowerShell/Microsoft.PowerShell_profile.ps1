
# =========================================================
# PowerShell — Black Metal / Khold
# Dell Inspiron 7501
# =========================================================


# ---------------------------------------------------------
# Startup Directory
# ---------------------------------------------------------

Set-Location $HOME


# ---------------------------------------------------------
# Console Appearance
# ---------------------------------------------------------

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"


# ---------------------------------------------------------
# PSReadLine — Syntax Highlighting
# ---------------------------------------------------------

Import-Module PSReadLine

Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -HistoryNoDuplicates

Set-PSReadLineOption -Colors @{
    Command   = "#E8E8E8"
    Parameter = "#777777"
    String    = "#A26862"
    Operator  = "#777777"
    Variable  = "#E8E8E8"
    Number    = "#A26862"
    Type      = "#E8E8E8"
    Comment   = "#777777"
}


# ---------------------------------------------------------
# Starship — Custom Prompt
# ---------------------------------------------------------

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}


# ---------------------------------------------------------
# Fastfetch — Startup System Information
# ---------------------------------------------------------

if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch
}

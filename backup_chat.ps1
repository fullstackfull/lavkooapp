# PowerShell Script to Backup Antigravity Chat History and Logs
$conversationId = "ef430b4c-30e4-4ac1-8fcc-e06d0e2349ae"
$sourceDir = "C:\Users\mahmoudosama\.gemini\antigravity-ide\brain\$conversationId"
$targetDir = Join-Path -Path $PSScriptRoot -ChildPath "chat_history_backup"

Write-Host "Backing up chat history from Gemini app data directory..."
Write-Host "Source: $sourceDir"
Write-Host "Destination: $targetDir"

if (-not (Test-Path $sourceDir)) {
    Write-Warning "Source directory not found. Please ensure the path is correct."
    Exit
}

if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
}

# Copy logs
$logsSource = Join-Path $sourceDir ".system_generated\logs"
$logsTarget = Join-Path $targetDir "logs"
if (Test-Path $logsSource) {
    New-Item -ItemType Directory -Force -Path $logsTarget | Out-Null
    Copy-Item -Path "$logsSource\*" -Destination $logsTarget -Recurse -Force
}

# Copy markdown artifacts
Get-ChildItem -Path $sourceDir -Filter "*.md" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $targetDir -Force
}

# Copy media artifacts
Get-ChildItem -Path $sourceDir -Filter "*.png" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $targetDir -Force
}

Write-Host "Success! Chat backup completed inside your project workspace under 'chat_history_backup'."

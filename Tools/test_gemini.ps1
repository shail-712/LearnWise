<#
.SYNOPSIS
    Sends the LearnWise prompt to Gemini and prints the JSON the model returns.
    Use it on Windows to tune the prompt and schema before the app runs on a Mac.

.EXAMPLE
    $env:GEMINI_API_KEY = "your_key"
    .\Tools\test_gemini.ps1
    .\Tools\test_gemini.ps1 -Topic "SwiftUI" -Level intermediate -Goal "Build my first app"
    .\Tools\test_gemini.ps1 -Topic "Graphs" -OutFile Tools\output\graphs.json
#>
param(
    [string]$Topic = "Dynamic Programming",
    [ValidateSet("beginner", "intermediate", "advanced")]
    [string]$Level = "beginner",
    [string]$Goal = "General understanding",
    [string]$Model = "gemini-2.5-flash",
    [string]$OutFile
)

$ErrorActionPreference = "Stop"

if (-not $env:GEMINI_API_KEY) {
    Write-Error 'Set your key first:  $env:GEMINI_API_KEY = "your_key"'
}

# Same system prompt and schema as PromptBuilder.swift. Only the user prompt changes.
$request = Get-Content -Raw -Encoding UTF8 "$PSScriptRoot\gemini_request.json" | ConvertFrom-Json
$request.contents[0].parts[0].text = "Topic: $Topic`nSkill level: $Level`nGoal: $Goal"
$body = ConvertTo-Json -InputObject $request -Depth 20

$uri = "https://generativelanguage.googleapis.com/v1beta/models/${Model}:generateContent"
$headers = @{ "x-goog-api-key" = $env:GEMINI_API_KEY }

Write-Host "Asking $Model about '$Topic' ($Level)..." -ForegroundColor Cyan
$timer = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers `
        -ContentType "application/json; charset=utf-8" `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
} catch {
    Write-Host "Request failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message }
    exit 1
}
$timer.Stop()

$candidate = $response.candidates[0]
if ($candidate.finishReason -ne "STOP") {
    Write-Host "finishReason: $($candidate.finishReason)" -ForegroundColor Yellow
}

$text = ($candidate.content.parts | ForEach-Object { $_.text }) -join ""
$result = $text | ConvertFrom-Json
$pretty = ConvertTo-Json -InputObject $result -Depth 20

if ($OutFile) {
    $fullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile)
    New-Item -ItemType Directory -Force (Split-Path $fullPath) | Out-Null
    [System.IO.File]::WriteAllText($fullPath, $pretty)
    Write-Host "Saved to $OutFile" -ForegroundColor Green
} else {
    $pretty
}

# A quick summary helps when comparing prompt changes.
Write-Host ""
Write-Host ("{0} resources, {1} roadmap steps, {2:N1}s" -f $result.resources.Count, $result.roadmap.Count, $timer.Elapsed.TotalSeconds) -ForegroundColor Cyan
$result.resources | Group-Object type | ForEach-Object { Write-Host ("  {0,-9} {1}" -f $_.Name, $_.Count) }

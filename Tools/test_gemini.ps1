<#
.SYNOPSIS
    Sends the LearnWise prompt to Gemini and prints the JSON the model returns.
    Use it on Windows to tune the prompt and schema before the app runs on a Mac.

    The key is read from .env in the project root (copy .env.example), or from $env:GEMINI_API_KEY.

.EXAMPLE
    .\Tools\test_gemini.ps1
    .\Tools\test_gemini.ps1 -Topic "SwiftUI" -Level intermediate -Goal "Build my first app"
    .\Tools\test_gemini.ps1 -Topic "Graphs" -OutFile Tools\output\graphs.json
#>
param(
    [string]$Topic = "Dynamic Programming",
    [ValidateSet("beginner", "intermediate", "advanced")]
    [string]$Level = "beginner",
    [string]$Goal = "General understanding",
    [string]$Model,
    [string]$OutFile
)

$ErrorActionPreference = "Stop"

# Load KEY=value lines from .env. Variables already set in the shell take priority.
$envFile = Join-Path $PSScriptRoot "..\.env"
if (Test-Path $envFile) {
    foreach ($line in Get-Content $envFile -Encoding UTF8) {
        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$' -and -not $line.TrimStart().StartsWith("#")) {
            $name = $Matches[1]
            $value = $Matches[2].Trim('"', "'")
            if ($value -and -not [Environment]::GetEnvironmentVariable($name)) {
                [Environment]::SetEnvironmentVariable($name, $value, "Process")
            }
        }
    }
}

if (-not $env:GEMINI_API_KEY) {
    Write-Error "No Gemini key found. Add GEMINI_API_KEY to .env in the project root (see .env.example)."
}
if (-not $Model) {
    $Model = if ($env:GEMINI_MODEL) { $env:GEMINI_MODEL } else { "gemini-3.8-flash" }
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
    # Windows PowerShell 5.1 often leaves ErrorDetails empty, so read the body directly.
    $detail = $_.ErrorDetails.Message
    if (-not $detail -and $_.Exception.Response) {
        $detail = (New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd()
    }
    if ($detail) { Write-Host $detail }
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

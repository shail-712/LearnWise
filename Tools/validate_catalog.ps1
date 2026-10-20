<#
.SYNOPSIS
    Checks LearnWise/Resources/resources_catalog.json before it goes into the app:
    valid types and levels, LeetCode slugs, duplicate keywords, and that every URL
    passes the same allow-list LinkResolver uses (read from Constants.swift).

.EXAMPLE
    .\Tools\validate_catalog.ps1
#>
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot
$catalog = Get-Content -Raw -Encoding UTF8 "$root\LearnWise\Resources\resources_catalog.json" | ConvertFrom-Json
$constants = Get-Content -Raw -Encoding UTF8 "$root\LearnWise\Utilities\Constants.swift"

function Get-HostList([string]$name) {
    $match = [regex]::Match($constants, "static let $name = \[(.*?)\]", "Singleline")
    if (-not $match.Success) { throw "Couldn't find AllowedHosts.$name in Constants.swift" }
    [regex]::Matches($match.Groups[1].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
}
$hosts = @{ course = Get-HostList "course"; notes = Get-HostList "notes"; pdf = Get-HostList "pdf" }
$academic = Get-HostList "academic"

function Test-Hosted([string]$hostName, [string[]]$domains) {
    foreach ($d in $domains) { if ($hostName -eq $d -or $hostName.EndsWith(".$d")) { return $true } }
    $false
}

$types = "video", "pdf", "course", "leetcode", "notes"
$levels = "beginner", "intermediate", "advanced"
$categories = "DSA", "Web", "iOS", "ML", "Math", "Systems", "Databases", "General"
$problems = [System.Collections.Generic.List[string]]::new()
$keywordOwner = @{}
$total = 0

foreach ($entry in $catalog) {
    if ($categories -notcontains $entry.category) { $problems.Add("$($entry.topic): unknown category '$($entry.category)'") }
    foreach ($kw in @($entry.keywords) + $entry.topic) {
        $k = $kw.ToLower()
        if ($keywordOwner.ContainsKey($k) -and $keywordOwner[$k] -ne $entry.topic) {
            $problems.Add("keyword '$k' is used by both '$($keywordOwner[$k])' and '$($entry.topic)'")
        }
        $keywordOwner[$k] = $entry.topic
    }
    foreach ($r in $entry.resources) {
        $total++
        $where = "$($entry.topic) / $($r.title)"
        if ($types -notcontains $r.type) { $problems.Add("${where}: bad type '$($r.type)'") }
        if ($levels -notcontains $r.difficulty) { $problems.Add("${where}: bad difficulty '$($r.difficulty)'") }
        foreach ($field in "title", "description", "source", "searchQuery") {
            if (-not $r.$field) { $problems.Add("${where}: missing $field") }
        }
        if ($r.type -eq "leetcode" -and $r.leetcodeSlug -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
            $problems.Add("${where}: bad leetcodeSlug '$($r.leetcodeSlug)'")
        }
        if ($r.url) {
            $uri = [Uri]$r.url
            # Mirrors LinkResolver: videos and LeetCode never use the model URL; pdf, course and
            # notes keep https links on their allow-list or on a university domain.
            $ok = $false
            if ($uri.Scheme -eq "https" -and $hosts.ContainsKey($r.type)) {
                $ok = (Test-Hosted $uri.Host $hosts[$r.type]) -or (Test-Hosted $uri.Host $academic)
            }
            if (-not $ok) { $problems.Add("${where}: URL would be replaced by a search link ($($uri.Host))") }
        }
    }
}

"{0} topics, {1} resources" -f $catalog.Count, $total
$catalog | Group-Object category | ForEach-Object { "  {0,-10} {1} topics" -f $_.Name, $_.Count }
$all = $catalog | ForEach-Object { $_.resources }
"  types:  " + (($all | Group-Object type | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ", ")
"  levels: " + (($all | Group-Object difficulty | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ", ")
"  with URL: $(@($all | Where-Object url).Count)"

if ($problems.Count) {
    ""
    "$($problems.Count) problem(s):"
    $problems | ForEach-Object { "  - $_" }
    exit 1
}
"No problems found."

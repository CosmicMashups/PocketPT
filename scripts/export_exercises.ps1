$ErrorActionPreference = 'Stop'

$csvPath = Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'assets/data/exercises_dup.csv'
$outDir = Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'docs'
$outPath = Join-Path $outDir 'exercises_distinct.md'

if (-not (Test-Path $csvPath)) { throw "CSV not found at $csvPath" }
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$ex = Import-Csv -Path $csvPath | Select-Object -ExpandProperty Exercise | Sort-Object -Unique
$lines = @('# Distinct Exercises','','')
foreach ($e in $ex) { $lines += ('- ' + $e) }

Set-Content -Path $outPath -Value $lines -Encoding UTF8
Write-Host "Wrote $($ex.Count) distinct exercises to $outPath"






























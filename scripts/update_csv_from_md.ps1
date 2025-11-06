# Run this file from the project root (where /assets and /scripts subdirs exist)
$mdPath = "assets/data/exercises_with_major_muscles.md"
$csvPath = "assets/data/exercises_dup.csv"
$tmpPath = "assets/data/exercises_dup_UPDATED_AI.csv"

# Identify major muscles for filtering
$majorMuscles = @("Deltoids","Biceps","Triceps","Cervical Muscle","Quadriceps","Hamstrings","Calf","Ankle","Gluteals","Abdominals","Obliques","Lower Back","Multifidus","Chest")

$md = Get-Content $mdPath -Raw
$map = @{}
$matches = [regex]::Matches($md, '(?m)^### Exercise: (.*?)\r?\n\*\*Muscle_Involved:\*\*\s*(.*?)\s*\r?\n\*\*Majorly_Affected_Muscles:\*\* (.+?)\r?\n')
foreach ($m in $matches) {
    $ex = $m.Groups[1].Value.Trim()
    $primary = $m.Groups[2].Value.Trim()
    $mus = $m.Groups[3].Value.Trim()
    if (-not $map.ContainsKey($ex)) {
        $map[$ex] = @{ Major=$mus; Primary=$primary }
    }
}

$rows = Import-Csv $csvPath
foreach ($row in $rows) {
    $ex = $row.Exercise.Trim()
    if ($map.ContainsKey($ex)) {
        $majors = $map[$ex].Major -split ',' | ForEach-Object { $_.Trim() }
        $primary = $map[$ex].Primary.Trim()
        # Bulletproof (case/whitespace): Exclude Muscle_Involved and keep only major muscles
        $majorsFiltered = @()
        foreach ($m in $majors) {
            $mt = $m.Trim().ToLowerInvariant()
            $pt = $primary.ToLowerInvariant()
            if ($majorMuscles -contains $m -and $mt -ne $pt) { $majorsFiltered += $m.Trim() }
        }
        $row.Other_Muscles = ($majorsFiltered -join ', ')
    }
}
$rows | Export-Csv $tmpPath -NoTypeInformation -Encoding UTF8
Write-Host "Updated (no overlap): $($map.Count) exercises mapped. Output: $tmpPath"

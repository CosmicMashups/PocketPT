$ErrorActionPreference = 'Stop'

$path = Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'assets/data/exercises_dup.csv'

if (-not (Test-Path $path)) {
  throw "CSV not found at $path"
}

function Get-BaseOtherMuscles {
  param(
    [string]$Exercise,
    [string]$Primary
  )

  $e = ($Exercise | ForEach-Object { $_.ToLowerInvariant() })
  switch ($Primary) {
    'Deltoids' {
      if ($e -match 'press|push|push-up') { return 'Biceps, Triceps, Chest' }
      elseif ($e -match 'fly') { return 'Biceps, Chest, Abdominals' }
      else { return 'Biceps, Triceps, Chest' }
    }
    'Biceps' {
      if ($e -match 'row|pull') { return 'Deltoids, Chest' }
      else { return 'Deltoids' }
    }
    'Triceps' { return 'Deltoids, Chest, Abdominals' }
    'Chest' {
      if ($e -match 'fly') { return 'Deltoids, Abdominals' }
      else { return 'Deltoids, Triceps, Abdominals' }
    }
    'Neck' { return 'Deltoids' }
    'Cervical Muscle' { return 'Deltoids' }
    'Quadriceps' { return 'Hamstrings, Gluteals' }
    'Hamstrings' { return 'Gluteals, Lower Back' }
    'Calf' { return 'Ankle, Hamstrings' }
    'Ankle' { return 'Calf' }
    'Gluteals' { return 'Hamstrings, Quadriceps, Lower Back' }
    'Abdominals' { return 'Obliques, Lower Back' }
    'Obliques' { return 'Abdominals' }
    'Lower Back' { return 'Abdominals, Gluteals, Hamstrings' }
    'Multifidus' { return 'Lower Back, Abdominals' }
    Default { return '' }
  }
}

# Define related major muscles per primary for generating diverse combos
$relatedByPrimary = @{
  'Deltoids'       = @('Biceps','Triceps','Chest','Abdominals')
  'Biceps'         = @('Deltoids','Chest','Triceps')
  'Triceps'        = @('Deltoids','Chest','Abdominals')
  'Chest'          = @('Deltoids','Triceps','Abdominals')
  'Neck'           = @('Deltoids','Cervical Muscle')
  'Cervical Muscle'= @('Deltoids','Neck')
  'Quadriceps'     = @('Hamstrings','Gluteals','Calf')
  'Hamstrings'     = @('Gluteals','Lower Back','Quadriceps')
  'Calf'           = @('Ankle','Hamstrings','Quadriceps')
  'Ankle'          = @('Calf','Hamstrings','Quadriceps')
  'Gluteals'       = @('Hamstrings','Quadriceps','Lower Back')
  'Abdominals'     = @('Obliques','Lower Back','Chest')
  'Obliques'       = @('Abdominals','Lower Back')
  'Lower Back'     = @('Abdominals','Gluteals','Hamstrings')
  'Multifidus'     = @('Lower Back','Abdominals')
}

function Get-OrderedRelated {
  param(
    [string]$Exercise,
    [string]$Primary
  )
  $e = ($Exercise | ForEach-Object { $_.ToLowerInvariant() })
  $related = @()
  if ($relatedByPrimary.ContainsKey($Primary)) { $related = @($relatedByPrimary[$Primary]) }

  # Light contextual filtering of related order
  if ($Primary -eq 'Chest') {
    if ($e -match 'fly') { $related = @('Deltoids','Abdominals','Triceps') }
    elseif ($e -match 'push|press|push-up') { $related = @('Deltoids','Triceps','Abdominals') }
  }
  elseif ($Primary -eq 'Deltoids') {
    if ($e -match 'raise|abduction|lateral|front') { $related = @('Biceps','Triceps','Chest','Abdominals') }
    elseif ($e -match 'press|push') { $related = @('Triceps','Chest','Biceps','Abdominals') }
  }
  elseif ($Primary -eq 'Biceps') {
    if ($e -match 'curl|supination|pronation') { $related = @('Deltoids','Chest','Triceps') }
    elseif ($e -match 'row|pull') { $related = @('Deltoids','Chest','Triceps') }
  }
  elseif ($Primary -eq 'Neck' -or $Primary -eq 'Cervical Muscle') {
    $related = @('Deltoids','Cervical Muscle')
  }
  return $related
}

function Get-AllCombos {
  param([string[]]$items)
  $combos = @()
  $n = $items.Count
  for ($i=0; $i -lt $n; $i++) {
    for ($j=$i+1; $j -lt $n; $j++) {
      $combos += ,(@($items[$i], $items[$j]))
      for ($k=$j+1; $k -lt $n; $k++) {
        $combos += ,(@($items[$i], $items[$j], $items[$k]))
      }
    }
  }
  # Convert to formatted strings
  return $combos | ForEach-Object { ($_ -join ', ') }
}

function Get-DeterministicIndex {
  param([string]$key, [int]$mod)
  if ($mod -le 0) { return 0 }
  $sum = 0
  foreach ($ch in $key.ToCharArray()) { $sum += [int][char]$ch }
  return [math]::Abs($sum) % $mod
}

$rows = Import-Csv -Path $path

# Assign Other_Muscles with group-level uniqueness preference
$groups = $rows | Group-Object Muscle_Involved
foreach ($g in $groups) {
  $used = New-Object 'System.Collections.Generic.HashSet[string]'
  foreach ($row in $g.Group) {
    $primary = $row.Muscle_Involved
    $exercise = $row.Exercise
    $base = Get-BaseOtherMuscles -Exercise $exercise -Primary $primary
    $related = Get-OrderedRelated -Exercise $exercise -Primary $primary
    $combos = Get-AllCombos -items $related

    # Ensure the base suggestion is considered first if valid
    $ordered = @()
    if ($base -and ($combos -contains $base)) { $ordered += $base }
    $ordered += ($combos | Where-Object { $_ -ne $base })
    if ($ordered.Count -eq 0) { $ordered = @($base) }

    # Pick deterministic starting index based on exercise name to spread choices
    $start = Get-DeterministicIndex -key $exercise -mod $ordered.Count
    $choice = $null
    for ($offset = 0; $offset -lt $ordered.Count; $offset++) {
      $candidate = $ordered[($start + $offset) % $ordered.Count]
      if (-not [string]::IsNullOrWhiteSpace($candidate)) {
        if ($used.Add($candidate)) { $choice = $candidate; break }
      }
    }
    if (-not $choice) { $choice = $base }
    $row.Other_Muscles = $choice
  }
}

$rows | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8

Write-Host "Updated Other_Muscles for $($rows.Count) rows in $path"



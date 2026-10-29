param(
    [Parameter(Mandatory = $true)][string]$GodotBin
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$resolvedGodot = (Resolve-Path -LiteralPath $GodotBin).Path
Push-Location -LiteralPath $projectRoot
try {
    New-Item -ItemType Directory -Force -Path artifacts | Out-Null
    Set-Content -LiteralPath artifacts\.gdignore -Value ''
    $importOutput = & $resolvedGodot --headless --path $projectRoot --log-file artifacts/import.log --import 2>&1
    $importCode = $LASTEXITCODE
    $importOutput | Set-Content -LiteralPath artifacts/import-output.log
    if ($importCode -ne 0 -or ($importOutput -match 'SCRIPT ERROR:|^ERROR:')) { throw 'Godot import failed. See artifacts/import-output.log.' }

    python tools/solver/verify_stages.py
    if ($LASTEXITCODE -ne 0) { throw 'Independent solver verification failed.' }
    foreach ($test in @('tools/smoke_test.gd', 'tests/gameplay_flow.gd', 'tests/shadow_layers_flow.gd')) {
        $stem = [IO.Path]::GetFileNameWithoutExtension($test)
        $testOutput = & $resolvedGodot --headless --debug --ignore-error-breaks --path $projectRoot --log-file "artifacts/$stem.log" --script $test 2>&1
        $testCode = $LASTEXITCODE
        $testOutput | Set-Content -LiteralPath "artifacts/$stem-output.log"
        if ($testCode -ne 0 -or ($testOutput -match 'SCRIPT ERROR:|^ERROR:|^WARNING:') -or -not ($testOutput -match 'PASS')) {
            $testOutput | Write-Output
            throw "Verification failed: $test"
        }
        $testOutput | Where-Object { $_ -match 'PASS' } | Write-Output
    }
    Write-Output 'AFTERLUX verification: PASS (100 PAR proofs, unique optimal solutions, rule and gameplay checks).'
}
finally {
    Pop-Location
}

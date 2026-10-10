<#
Порядок работы:
1. Проверяет наличие карты, Current Script\war3map.j и программ из toolkit.
2. Копирует карту, скрипт и программы во временную папку вне репозитория.
3. Распаковывает карту через Ladik's MPQ Editor и находит встроенный war3map.j.
4. Через Ladik удаляет старый war3map.j, добавляет новый и проверяет его содержимое.
5. Собирает и сжимает карту в SLK через W3x2Lni.
6. При ошибках или предупреждениях упаковки выводит отчёт и сохраняет исходную карту.
7. При успешной сборке заменяет исходную карту, если входные файлы не изменились.
8. Удаляет временную папку, включая копии программ и логи, даже при ошибке.

Запуск из корня репозитория:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Update-Map.ps1
Другую карту можно указать параметром -MapPath.
#>
[CmdletBinding()]
param(
    [string]$MapPath,
    [string]$ScriptPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $MapPath) { $MapPath = Join-Path $PSScriptRoot 'Map\ross\BvO_Rossoliny_1.1a.w3x' }
if (-not $ScriptPath) { $ScriptPath = Join-Path $PSScriptRoot 'Current Script\war3map.j' }

function Invoke-HiddenTool {
    param([string]$ExecutablePath, [string[]]$ToolArguments, [string]$WorkingPath)
    $outputPath = Join-Path $WorkingPath 'tool.stdout.log'
    $errorPath = Join-Path $WorkingPath 'tool.stderr.log'
    $quotedArguments = ($ToolArguments | ForEach-Object {
        if ($_ -match '\s') { '"' + $_ + '"' } else { $_ }
    }) -join ' '
    $process = Start-Process -FilePath $ExecutablePath -ArgumentList $quotedArguments `
        -WorkingDirectory $WorkingPath -WindowStyle Hidden -Wait -PassThru `
        -RedirectStandardOutput $outputPath -RedirectStandardError $errorPath
    $toolOutput = [IO.File]::ReadAllText($outputPath) + [IO.File]::ReadAllText($errorPath)
    Write-Verbose $toolOutput
    if ($process.ExitCode -ne 0 -or $toolOutput -match '(?im)\b(failed|error code|too many parameters|not enough parameters|syntax is incorrect)\b') {
        throw "Tool failed: $ExecutablePath`n$toolOutput"
    }
}

function Invoke-MpqCommands {
    param([string[]]$Commands)
    $commandsPath = Join-Path $temporaryPath 'mpq-commands.txt'
    [IO.File]::WriteAllLines($commandsPath, $Commands, [Text.UTF8Encoding]::new($false))
    Invoke-HiddenTool $mpqEditorPath @('/console', $commandsPath) $temporaryPath
}

$converterSourcePath = Join-Path $PSScriptRoot 'toolkit\W3x2Lni v2.7.2'
$mpqEditorSourcePath = Join-Path $PSScriptRoot 'toolkit\Ladiks MPQ Editor\x64\MPQEditor.exe'
$listfileSourcePath = Join-Path $PSScriptRoot 'lisfile\listfile.txt'
foreach ($requiredPath in @($MapPath, $ScriptPath, $mpqEditorSourcePath, $listfileSourcePath, (Join-Path $converterSourcePath 'w2l.exe'))) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "File not found: $requiredPath"
    }
}
$MapPath = (Resolve-Path -LiteralPath $MapPath).ProviderPath
$ScriptPath = (Resolve-Path -LiteralPath $ScriptPath).ProviderPath
$originalMapHash = (Get-FileHash -LiteralPath $MapPath).Hash
$temporaryParentPath = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
$temporaryPath = Join-Path $temporaryParentPath ('bvo-map-update-' + [Guid]::NewGuid().ToString('N'))

try {
    New-Item -ItemType Directory -Path $temporaryPath | Out-Null
    $workingMapPath = Join-Path $temporaryPath 'input.w3x'
    $workingScriptPath = Join-Path $temporaryPath 'war3map.j'
    $converterPath = Join-Path $temporaryPath 'converter'
    $mpqEditorPath = Join-Path $temporaryPath 'MPQEditor.exe'
    $listfilePath = Join-Path $temporaryPath 'listfile.txt'
    $extractedPath = Join-Path $temporaryPath 'extracted'
    $outputMapPath = Join-Path $temporaryPath 'output.w3x'
    Copy-Item -LiteralPath $MapPath -Destination $workingMapPath
    Copy-Item -LiteralPath $ScriptPath -Destination $workingScriptPath
    Copy-Item -LiteralPath $converterSourcePath -Destination $converterPath -Recurse
    Copy-Item -LiteralPath $mpqEditorSourcePath -Destination $mpqEditorPath
    Copy-Item -LiteralPath $listfileSourcePath -Destination $listfilePath
    $scriptHash = (Get-FileHash -LiteralPath $workingScriptPath).Hash

    # Дополняет внешний listfile именами локальных ресурсов, не меняя исходный listfile.
    $resourceNames = foreach ($resourceFolder in @('ReplaceableTextures', 'Sounds')) {
        $resourcePath = Join-Path $PSScriptRoot $resourceFolder
        if (Test-Path -LiteralPath $resourcePath -PathType Container) {
            Get-ChildItem -LiteralPath $resourcePath -File -Recurse | ForEach-Object {
                $_.FullName.Substring($PSScriptRoot.Length + 1)
            }
        }
    }
    [IO.File]::AppendAllText($listfilePath, ("`r`n" + ($resourceNames -join "`r`n") + "`r`n"), [Text.UTF8Encoding]::new($false))

    # Настройки и исправление проверки стандартного SpellBook затрагивают только временную копию.
    $configPath = Join-Path $converterPath 'config.ini'
    $configText = [IO.File]::ReadAllText($configPath) -replace '(?m)^lang\s*=.*$', 'lang = enUS'
    [IO.File]::WriteAllText($configPath, $configText, [Text.UTF8Encoding]::new($false))
    $checkerPath = Join-Path $converterPath 'script\core\slk\frontend_extracheck.lua'
    $checkerText = [IO.File]::ReadAllText($checkerPath).Replace(
        'if not ORDER[order] then',
        "if not ORDER[order] and not (skill._code == 'Aspb' and order == 'spellbook') then")
    [IO.File]::WriteAllText($checkerPath, $checkerText, [Text.UTF8Encoding]::new($false))

    Write-Host 'Extracting map with Ladik...'
    New-Item -ItemType Directory -Path $extractedPath | Out-Null
    $commands = [Collections.Generic.List[string]]::new()
    $commands.Add('open "' + $workingMapPath + '" "' + $listfilePath + '"')
    $commands.Add('extract "' + $workingMapPath + '" "*" "' + $extractedPath + '" /fp')
    $commands.Add('close')
    $commands.Add('exit')
    Invoke-MpqCommands $commands.ToArray()

    $embeddedScriptPaths = @('war3map.j', 'scripts\war3map.j') | Where-Object {
        Test-Path -LiteralPath (Join-Path $extractedPath $_) -PathType Leaf
    }
    if (-not $embeddedScriptPaths) { throw 'Embedded war3map.j was not found.' }
    $targetScriptName = @($embeddedScriptPaths)[0]
    $commands.Clear()
    $commands.Add('open "' + $workingMapPath + '" "' + $listfilePath + '"')
    foreach ($embeddedScriptName in $embeddedScriptPaths) {
        $commands.Add('delete "' + $workingMapPath + '" "' + $embeddedScriptName + '"')
        Remove-Item -LiteralPath (Join-Path $extractedPath $embeddedScriptName)
    }
    $commands.Add('add "' + $workingMapPath + '" "' + $workingScriptPath + '" "' + $targetScriptName + '" /c')
    $commands.Add('extract "' + $workingMapPath + '" "' + $targetScriptName + '" "' + $extractedPath + '" /fp')
    $commands.Add('close')
    $commands.Add('exit')
    Invoke-MpqCommands $commands.ToArray()
    if ((Get-FileHash -LiteralPath (Join-Path $extractedPath $targetScriptName)).Hash -ne $scriptHash) {
        throw 'The inserted script differs from the input script.'
    }

    # Входная папка позволяет упаковывать и SLK-карты без внутреннего (listfile).
    Write-Host 'Building SLK with W3x2Lni...'
    $reportPath = Join-Path $converterPath 'log\report.log'
    if (Test-Path -LiteralPath $reportPath) { Remove-Item -LiteralPath $reportPath }
    Invoke-HiddenTool (Join-Path $converterPath 'w2l.exe') @('slk', $extractedPath, $outputMapPath) $temporaryPath
    if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) { throw 'W3x2Lni did not produce a report.' }
    $report = [IO.File]::ReadAllText($reportPath)
    if ($report -notmatch '(?m)^Result: 0 errors, 0 warnings\s*$') {
        throw "SLK build rejected. Original map preserved.`n$report"
    }
    if (-not (Test-Path -LiteralPath $outputMapPath -PathType Leaf) -or (Get-Item -LiteralPath $outputMapPath).Length -eq 0) {
        throw 'W3x2Lni did not produce a map.'
    }
    if ((Get-FileHash -LiteralPath $MapPath).Hash -ne $originalMapHash -or
        (Get-FileHash -LiteralPath $ScriptPath).Hash -ne $scriptHash) {
        throw 'Input files changed during the build. Original map preserved.'
    }
    [IO.File]::Replace($outputMapPath, $MapPath, (Join-Path $temporaryPath 'original.w3x'))
    Write-Host "Map updated: $MapPath"
    Write-Host 'Result: 0 errors, 0 warnings'
}
finally {
    if ([IO.Path]::GetDirectoryName($temporaryPath) -ne $temporaryParentPath -or
        [IO.Path]::GetFileName($temporaryPath) -notmatch '^bvo-map-update-[a-f0-9]{32}$') {
        throw 'Unsafe temporary cleanup path.'
    }
    if (Test-Path -LiteralPath $temporaryPath -PathType Container) {
        Remove-Item -LiteralPath $temporaryPath -Recurse -Force
    }
}

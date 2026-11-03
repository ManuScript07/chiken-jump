param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',
    [string]$JavaHome = $env:JAVA_HOME,
    [string]$AndroidSdk = $env:ANDROID_HOME
)

$ErrorActionPreference = 'Stop'
$projectDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$buildDir = Join-Path $projectDir 'builds'
$keyDir = Join-Path $env:APPDATA 'Godot/keystores'
$godot = (Get-Command godot_console.exe -ErrorAction Stop).Source

if (-not $JavaHome) {
    $studio = Get-ItemProperty 'HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall/*',
        'HKCU:/SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall/*' -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -eq 'Android Studio' } | Select-Object -First 1
    if ($studio.DisplayIcon) {
        $studioExe = $studio.DisplayIcon.Trim('"') -replace ',\d+$', ''
        $JavaHome = Join-Path (Split-Path (Split-Path $studioExe -Parent) -Parent) 'jbr'
    }
}
if (-not $AndroidSdk) { $AndroidSdk = Join-Path $env:LOCALAPPDATA 'Android/Sdk' }
if (-not (Test-Path -LiteralPath (Join-Path $JavaHome 'bin/java.exe'))) {
    throw 'Specify -JavaHome with a compatible JDK directory.'
}
if (-not (Test-Path -LiteralPath (Join-Path $AndroidSdk 'platform-tools/adb.exe'))) {
    throw 'Specify -AndroidSdk with the Android SDK directory.'
}

$signingKind = $Configuration.ToUpperInvariant()
$prefix = "GODOT_ANDROID_KEYSTORE_${signingKind}_"
$updates = @{ JAVA_HOME = $JavaHome; ANDROID_HOME = $AndroidSdk }
if ($Configuration -eq 'Release') {
    $keyFile = Join-Path $keyDir 'kuratenn-release.keystore'
    $passwordFile = Join-Path $keyDir 'kuratenn-release.password.xml'
    if (-not (Test-Path -LiteralPath $keyFile) -or -not (Test-Path -LiteralPath $passwordFile)) {
        throw 'The local release signing key or its protected password is missing.'
    }
    $secure = Import-Clixml -LiteralPath $passwordFile
    $buffer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { $password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($buffer) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($buffer) }
    $updates[$prefix + 'PATH'] = $keyFile
    $updates[$prefix + 'USER'] = 'kuratenn'
    $updates[$prefix + 'PASSWORD'] = $password
    $filename = 'kuratenn.apk'
} else {
    $updates[$prefix + 'PATH'] = Join-Path $keyDir 'debug.keystore'
    $updates[$prefix + 'USER'] = 'androiddebugkey'
    $updates[$prefix + 'PASSWORD'] = 'android'
    $filename = 'kuratenn-debug.apk'
}

$original = @{}
try {
    foreach ($name in $updates.Keys) {
        $original[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        [Environment]::SetEnvironmentVariable($name, $updates[$name], 'Process')
    }
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
    $output = Join-Path $buildDir $filename
    $temporary = Join-Path $buildDir ('pending-' + $filename)
    $flag = '--export-' + $Configuration.ToLowerInvariant()
    & $godot --headless --path $projectDir $flag Android $temporary
    if ($LASTEXITCODE -ne 0) { throw 'Godot Android export failed.' }
    $buildTools = Get-ChildItem -LiteralPath (Join-Path $AndroidSdk 'build-tools') -Directory |
        Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } |
        Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
    & (Join-Path $buildTools.FullName 'apksigner.bat') verify --verbose $temporary
    if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
    Move-Item -LiteralPath $temporary -Destination $output -Force
    $digest = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash
    [IO.File]::WriteAllText($output + '.sha256.txt', $digest + '  ' + $filename + [Environment]::NewLine)
    Write-Output ('APK: ' + $output)
} finally {
    foreach ($name in $original.Keys) {
        [Environment]::SetEnvironmentVariable($name, $original[$name], 'Process')
    }
    $password = $null
    $updates.Clear()
}

# Registra (o quita) Dexi Pro como plugin de Deswik CAD para el usuario actual, en TODAS las versiones de Deswik encontradas.
# Lo llaman Instalar.bat y Desinstalar.bat. Solo escribe en HKCU (no necesita administrador).
# Formato verificado en Deswik.Common.Plugins.Host 2024.2 (Plugins.LoadFromRegistry) y en las claves que Deswik crea:
#   HKCU\SOFTWARE\Deswik\<version>\Deswik.CAD\Plugins\<Nombre>  con SpecifyFilePath, FilePath, StartupClass, LoadOnStartup...
# Deswik carga <FilePath>\<Nombre>.dll y la clase "<Nombre>.<StartupClass>". Las versiones nuevas de Deswik copian los
# plugins de la version anterior la primera vez que se abren.
# Texto solo ASCII: se muestra en la consola de cmd.
param([ValidateSet('registrar', 'quitar')][string]$Accion = 'registrar', [string]$Carpeta = (Join-Path $env:APPDATA 'DexiPro'))
$ErrorActionPreference = 'Stop'
$nombre = 'DexiPro'
$base = 'HKCU:\SOFTWARE\Deswik'

# Versiones: carpetas "Deswik.Suite AAAA.N" en Program Files y claves AAAA.N ya creadas por Deswik en el registro
$versiones = New-Object System.Collections.Generic.List[string]
foreach ($pf in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:ProgramW6432) | ? { $_ } | Select -Unique) {
    $d = Join-Path $pf 'Deswik'
    if (Test-Path $d) {
        foreach ($s in Get-ChildItem $d -Directory) {
            if ($s.Name -match '^Deswik\.Suite (\d{4}\.\d+)' -and (Test-Path (Join-Path $s.FullName 'Deswik.CAD.exe'))) { $versiones.Add($Matches[1]) }
        }
    }
}
if (Test-Path $base) { Get-ChildItem $base | ? { $_.PSChildName -match '^\d{4}\.\d+$' } | % { $versiones.Add($_.PSChildName) } }
$versiones = $versiones | Sort-Object -Unique

if ($Accion -eq 'registrar') {
    if (-not (Test-Path (Join-Path $Carpeta "$nombre.dll"))) { Write-Host "[ERROR] No existe $Carpeta\$nombre.dll"; exit 1 }
    $instaladas = @($versiones | ? { $v = $_; @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | ? { $_ -and (Test-Path (Join-Path $_ "Deswik\Deswik.Suite $v\Deswik.CAD.exe")) } })
    if ($versiones.Count -eq 0) { Write-Host '[AVISO] No encontre Deswik CAD en esta PC. Se registra igual para 2024.2; tras instalar Deswik, ejecuta otra vez Instalar.bat.'; $versiones = @('2024.2') }
    $valores = [ordered]@{
        SpecifyFilePath = 'True'; FilePath = $Carpeta; Description = 'Dexi Pro - asistente de planeamiento minero'
        StartupClass = 'DeswikPlugin'; LoadOnStartup = 'True'; LoadIfPreviouslyOpen = 'True'
        PromptBeforeLoadingIfPreviouslyOpen = 'False'; RememberPosition = 'True'
        ShowAutoCloseButton = 'True'; ShowCloseButton = 'True'; AllowFloating = 'True'; AllowDockLeft = 'True'
        AllowDockRight = 'True'; AllowDockTop = 'True'; AllowDockBottom = 'True'; AllowDockFill = 'True'
    }
    foreach ($v in $versiones) {
        $k = "$base\$v\Deswik.CAD\Plugins\$nombre"
        New-Item -Path $k -Force | Out-Null
        foreach ($e in $valores.GetEnumerator()) { New-ItemProperty -Path $k -Name $e.Key -Value $e.Value -PropertyType String -Force | Out-Null }
        $marca = if ($instaladas -contains $v) { ' (instalada)' } else { '' }
        Write-Host "[OK] Plugin registrado en Deswik $v$marca"
    }
}
else {
    $n = 0
    if (Test-Path $base) {
        Get-ChildItem $base -Recurse -ErrorAction SilentlyContinue | ? { $_.PSChildName -eq 'Plugins' } | % {
            $pk = $_.PSPath
            if (Test-Path "$pk\$nombre") { Remove-Item "$pk\$nombre" -Recurse -Force; $n++ }
            # Posicion del panel que Deswik guarda como valores Plugin_DexiPro_*
            $_.Property | ? { $_ -like "Plugin_${nombre}_*" } | % { Remove-ItemProperty -Path $pk -Name $_ -Force }
        }
    }
    Write-Host "[OK] Plugin quitado de Deswik ($n registros)."
}

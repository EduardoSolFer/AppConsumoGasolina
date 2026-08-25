# ==========================================================================
# EXPORTAR BASE DE DATOS DESDE EL CELULAR AL PC
# ==========================================================================
# Requisitos:
#   - Celular conectado por USB con depuración activada
#   - ADB instalado (viene con Android Studio)
#
# Uso:
#   .\scripts\export_db.ps1
#
# Resultado:
#   Crea el archivo control_gasolina.db en la carpeta del proyecto.
#   Abrir con: DB Browser for SQLite (https://sqlitebrowser.org/)
# ==========================================================================

# ── Configuración ────────────────────────────────────────────────────────
$paquete = "com.example.control_gasolina"
$nombreDB = "control_gasolina.db"
$rutaADB = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

# ── Verificar que adb existe ─────────────────────────────────────────────
if (-not (Test-Path $rutaADB)) {
    Write-Error "ADB no encontrado en $rutaADB"
    Write-Host "Instala Android Studio o agrega platform-tools al PATH" -ForegroundColor Yellow
    exit 1
}

# ── Verificar que hay un dispositivo conectado ────────────────────────────
$devices = & $rutaADB devices 2>&1 | Select-String -Pattern "device$"
if (-not $devices) {
    Write-Error "No hay dispositivos conectados. Conecta tu celular por USB y activa depuracion USB."
    exit 1
}
Write-Host "Dispositivo detectado" -ForegroundColor Green

# ── Paso 1: copiar la BD desde la app al sistema de archivos del celular ──
# (run-as nos da acceso a la carpeta privada de la app en modo debug)
Write-Host "Copiando base de datos desde el celular..."
& $rutaADB shell "run-as $paquete cp databases/$nombreDB /sdcard/$nombreDB"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Error al copiar. Asegurate de que la app ya se ejecuto al menos una vez."
    exit 1
}

# ── Paso 2: traer el archivo al PC ──────────────────────────────────────
Write-Host "Descargando al PC..."
& $rutaADB pull "/sdcard/$nombreDB" (Join-Path $PSScriptRoot ".." $nombreDB) 2>&1 | Out-Null

# ── Paso 3: limpiar el archivo temporal del celular ──────────────────────
& $rutaADB shell "rm /sdcard/$nombreDB" | Out-Null

$rutaLocal = Join-Path $PSScriptRoot ".." $nombreDB
if (Test-Path $rutaLocal) {
    $tamanio = (Get-Item $rutaLocal).Length / 1KB
    Write-Host ""
    Write-Host "  Base de datos exportada: $nombreDB ($([math]::Round($tamanio, 1)) KB)" -ForegroundColor Green
    Write-Host "  Abrir con: DB Browser for SQLite" -ForegroundColor Cyan
    Write-Host "  Descarga: https://sqlitebrowser.org/" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Error "No se pudo exportar el archivo."
}

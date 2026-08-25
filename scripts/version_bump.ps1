# ==========================================================================
# SCRIPT DE VERSIONADO (equivalente a npm version patch/minor/major)
# ==========================================================================
#
# Uso:
#   .\version_bump.ps1 patch    →  1.0.0+1  →  1.0.1+2   (arreglo)
#   .\version_bump.ps1 minor    →  1.0.1+2  →  1.1.0+3   (funcionalidad nueva)
#   .\version_bump.ps1 major    →  1.1.0+3  →  2.0.0+4   (cambio grande/roto)
#
# Formato del version en pubspec.yaml:
#   version: X.Y.Z+N
#   └─┬─┘   │ │ │ └─┬─┘
#     │     │ │ │   └─ N = build number (Android/iOS siempre lo SUBE)
#     │     │ │ └───── Z = patch (arreglo de bugs)
#     │     │ └─────── Y = minor (funcionalidad nueva, sin romper nada)
#     │     └───────── X = major (cambios grandes / breaking)
#     └─────────────── Se muestra al usuario en la tienda
#
# Ejecutar desde la carpeta del proyecto:
#   cd F:\Documentos\Aplicaciones\control_gasolina
#   .\scripts\version_bump.ps1 patch
# ==========================================================================

param(
    [ValidateSet("patch", "minor", "major")]
    [string]$tipo = "patch"
)

$pubspecPath = Join-Path $PSScriptRoot ".." "pubspec.yaml"
$content = Get-Content $pubspecPath -Raw

# ── Paso 1: extraer la versión actual con regex ──────────────────────────
if ($content -match 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]
    $build = [int]$Matches[4]
} else {
    Write-Error "No se encontro una linea 'version: X.Y.Z+N' en pubspec.yaml"
    exit 1
}

# ── Paso 2: incrementar segun el tipo ────────────────────────────────────
switch ($tipo) {
    "major" { $major++; $minor = 0; $patch = 0 }
    "minor" { $minor++; $patch = 0 }
    "patch" { $patch++ }
}
$build++

# ── Paso 3: reemplazar la linea en el archivo ────────────────────────────
$newVersion = "$major.$minor.$patch+$build"
$newContent = $content -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $newVersion"
Set-Content $pubspecPath $newContent -NoNewline -Encoding UTF8

Write-Host ""
Write-Host "  Version actualizada: $newVersion" -ForegroundColor Green
Write-Host "  Tipo: $tipo" -ForegroundColor Gray
Write-Host "  Siguiente paso: flutter build apk --release" -ForegroundColor Cyan
Write-Host ""

# Reglas e Instrucciones del Proyecto: Control de Gasolina

## Resumen del Proyecto
Aplicación Flutter para control de cargas de gasolina y rendimiento de combustible (100% Offline con SQLite).

## Contexto de Archivos Clave
- `CONTEXT.md`: Archivo de contexto con la arquitectura completa, modelos, servicios y comandos de compilación.
- `lib/main.dart`: Inicialización FFI SQLite escritorio y formateo de fechas.
- `lib/data/database_helper.dart`: Helper Singleton SQLite.
- `lib/models/carga.dart`: Modelo de datos y fórmulas de rendimiento (km/L).
- `lib/screens/pantalla_principal.dart`: Dashboard principal de métricas e historial.
- `lib/screens/formulario_carga.dart`: Formulario con validaciones.

## Instrucciones de Desarrollo
1. Mantener las validaciones `!kIsWeb` y `Platform.isWindows` en la inicialización de SQLite.
2. Usar `flutter analyze` para verificar cambios.
3. Para construir APK de Android, asegurar la ruta del JDK a `E:\ProgramFiles\AndroidAndroid Studio\jbr`.

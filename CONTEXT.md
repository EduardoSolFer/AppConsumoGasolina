# 🚗 Contexto del Proyecto: Control de Gasolina (Flutter)

Este archivo de contexto documenta la arquitectura completa, historial de revisiones, configuración del entorno, comandos y el **estado exacto donde nos quedamos** en el proyecto **Control de Gasolina** para permitir la continuidad total desde **Antigravity**.

---

## 📌 Información General

* **Nombre del Proyecto**: `control_gasolina`
* **Tecnología**: Flutter (Dart ^3.11.4 / SDK ^3.41.6)
* **Plataformas Soportadas**: Android (Móvil) y Windows (Escritorio).
* **Almacenamiento**: SQLite Local (100% Offline, sin requerir internet).
* **Ramas Git**: 
  * `issues` (Rama actual limpia de control de gasolina v1.0.0).
  * `respaldo-mantenimiento` (Contiene el desarrollo completo del menú de mantenimiento, artículos y pantalla contenedora).
* **Última Actualización**: 21 de Septiembre, 2026.

---

## 📜 Historial de Revisiones y Trabajo Realizado

### 🔹 Sesión 1: "Revisión De Aplicación Gasolina"
1. **Diagnóstico y Corrección en Windows Escritorio**:
   * La aplicación fallaba al intentar acceder a SQLite en Windows debido a que `sqflite` requiere el inicializador FFI en escritorio.
   * Se modificó [`lib/main.dart`](file:///f:/Documentos/Aplicaciones/control_gasolina/lib/main.dart) y [`lib/data/database_helper.dart`](file:///f:/Documentos/Aplicaciones/control_gasolina/lib/data/database_helper.dart) agregando la inicialización `sqfliteFfiInit()` y `databaseFactory = databaseFactoryFfi` bajo la condición `if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS))`.
2. **Configuración del Entorno Gradle / Android JDK 17**:
   * Al compilar para Android (`flutter build apk`), Gradle fallaba por una ruta inválida de `JAVA_HOME`.
   * Se localizó la instalación válida de OpenJDK 17 en la ruta de Android Studio: `E:\ProgramFiles\AndroidAndroid Studio\jbr`.
   * Se configuró el motor de Flutter mediante: `flutter config --jdk-dir="E:\ProgramFiles\AndroidAndroid Studio\jbr"`.
   * Se ejecutó `flutter doctor`, obteniendo estado 100% funcional (0 errores).
3. **Compilación e Instalación en Dispositivo**:
   * Se construyó exitosamente el paquete de producción en:
     📂 [`build/app/outputs/flutter-apk/app-release.apk`](file:///f:/Documentos/Aplicaciones/control_gasolina/build/app/outputs/flutter-apk/app-release.apk) *(51.6 MB)*.
   * Se instaló la APK directamente en el smartphone Android conectado vía USB (`2311DRK48G`).

### 🔹 Sesión 2: "Gasoline App Review Request"
1. **Verificación del Repositorio**: Se confirmó la estabilidad del código con `flutter analyze` (0 errores).
2. **Generación de Documentación y Contexto**: Se crearon [`CONTEXT.md`](file:///f:/Documentos/Aplicaciones/control_gasolina/CONTEXT.md) y [`AGENTS.md`](file:///f:/Documentos/Aplicaciones/control_gasolina/AGENTS.md) para sincronizar el proyecto con Antigravity.

---

## 🏗️ Arquitectura del Proyecto

El proyecto está estructurado de forma limpia y modular:

```
lib/
├── main.dart                      # Punto de entrada de la app, bindings y FFI SQLite
├── data/
│   └── database_helper.dart       # Singleton SQLite, tabla 'cargas' y métodos CRUD
├── models/
│   └── carga.dart                 # Modelo de datos, mapeo Map/JSON y fórmulas (rendimiento km/L)
└── screens/
    ├── pantalla_principal.dart    # Dashboard de métricas (resumen general) e historial
    └── formulario_carga.dart      # Formulario modal/pantalla para crear o editar registros
```

### 📄 Componentes Clave

1. **[`lib/main.dart`](file:///f:/Documentos/Aplicaciones/control_gasolina/lib/main.dart)**:
   * Inicializa `WidgetsFlutterBinding.ensureInitialized()`.
   * Habilita FFI SQLite para escritorio (Windows) de forma segura (`!kIsWeb`).
   * Inicializa `initializeDateFormatting()` para el formato de fechas en español.

2. **[`lib/data/database_helper.dart`](file:///f:/Documentos/Aplicaciones/control_gasolina/lib/data/database_helper.dart)**:
   * **Singleton**: Mantiene una única conexión a la base de datos local SQLite.
   * Métodos CRUD: `insertarCarga`, `obtenerCargas`, `obtenerCarga(id)`, `actualizarCarga`, `eliminarCarga`.

3. **[`lib/models/carga.dart`](file:///f:/Documentos/Aplicaciones/control_gasolina/lib/models/carga.dart)**:
   * Campos: `id`, `fecha`, `kilometraje`, `litros`, `costoTotal`.
   * **Fórmulas**:
     * `precioPorLitro`: `costoTotal / litros`
     * `kmRecorridos(anterior)`: `kilometraje - anterior.kilometraje`
     * `rendimiento(anterior)`: `kmRecorridos / litros` (km por litro).

4. **[`lib/screens/pantalla_principal.dart`](file:///f:/Documentos/Aplicaciones/control_gasolina/lib/screens/pantalla_principal.dart)**:
   * Muestra tarjetas de resumen (Gasto total, Litros totales, Km recorridos, Rendimiento promedio).
   * Lista de cargas registradas ordenadas.
   * Botones para eliminar, agregar y editar registros.

5. **[`lib/screens/formulario_carga.dart`](file:///f:/Documentos/Aplicaciones/control_gasolina/lib/screens/formulario_carga.dart)**:
   * Valida que el odómetro sea superior al último registro almacenado.
   * Maneja controladores de texto (`TextEditingController`) y disposición en `dispose()`.

---

## ⚙️ Configuración del Entorno y Rutas de Compilación

* **Java JDK**: `E:\ProgramFiles\AndroidAndroid Studio\jbr`
* **APK Generado**: [`build/app/outputs/flutter-apk/app-release.apk`](file:///f:/Documentos/Aplicaciones/control_gasolina/build/app/outputs/flutter-apk/app-release.apk)

---

## 🛠️ Comandos Frecuentes

```bash
# Ejecutar en Windows Escritorio
flutter run -d windows

# Compilar APK Android
flutter build apk

# Instalar en celular Android conectado por USB
flutter install

# Analizar sintaxis y linters
flutter analyze
```

---

## 📍 ¿Dónde nos quedamos? (Estado Actual)
1. **La aplicación está 100% funcional y probada tanto en Windows escritorio como instalada en el dispositivo móvil Android.**
2. **El entorno de compilación está totalmente resuelto y configurado con JDK 17.**
3. **El proyecto cuenta con este archivo `CONTEXT.md` actualizado para que cualquier instancia de Antigravity pueda continuar el desarrollo directamente (p. ej. agregar estadísticas, exportar datos a Excel/PDF, o mejorar la UI).**

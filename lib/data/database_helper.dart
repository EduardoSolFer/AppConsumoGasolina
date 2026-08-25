/// ==========================================================================
/// DATABASE HELPER: toda la lógica de la base de datos local (OFFLINE)
/// ==========================================================================
/// Esta app funciona 100% SIN INTERNET. Los datos se guardan en una base de
/// datos SQLite, que es un archivo dentro del propio teléfono/PC.
///
/// - En Android/iOS usamos el paquete `sqflite` (el estándar en Flutter).
/// - En Windows/Linux `sqflite` no funciona directo, por eso agregamos
///   `sqflite_common_ffi`, que es la misma API pero implementada para PC.
///
/// Patrón usado: SINGLETON. Significa que aunque llames a DatabaseHelper()
/// muchas veces, TODAS obtienen la MISMA instancia y la MISMA conexión.
/// Así evitamos abrir la base de datos varias veces (lo cual da errores).
library;

import 'dart:io'; // Nos deja preguntar el sistema operativo (Platform.isWindows)

import 'package:path/path.dart'; // Une rutas de carpetas sin errores
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // API de SQLite + soporte PC

import '../models/carga.dart';

class DatabaseHelper {
  // --------------------------------------------------------------------------
  // CONFIGURACIÓN DEL SINGLETON
  // --------------------------------------------------------------------------

  /// Instancia única compartida. Empieza en null.
  static DatabaseHelper? _instancia;

  /// Constructor "fabriquero": siempre devuelve la misma instancia.
  factory DatabaseHelper() {
    _instancia ??= DatabaseHelper._(); // si no existe, la crea; si existe, la reutiliza
    return _instancia!;
  }

  /// Constructor privado (el guion bajo al inicio = solo visible en este archivo).
  DatabaseHelper._();

  // --------------------------------------------------------------------------
  // CONEXIÓN A LA BASE DE DATOS
  // --------------------------------------------------------------------------

  /// Referencia a la base de datos abierta. Se crea la primera vez que se usa.
  static Database? _baseDeDatos;

  /// Nombre del archivo físico donde viven tus datos.
  static const String _nombreBD = 'control_gasolina.db';

  /// Versión del esquema. Si algún día cambias las tablas (agregas columnas),
  /// sube este número a 2, 3... y Flutter ejecutará onUpgrade.
  static const int _version = 1;

  /// Abre (o crea) la base de datos. Es async porque leer el disco toma tiempo.
  Future<Database> get baseDeDatos async {
    // Solo la primera vez hace TODO el trabajo; las siguientes veces
    // simplemente devuelve la conexión ya abierta.
    _baseDeDatos ??= await _abrirBaseDeDatos();
    return _baseDeDatos!;
  }

  Future<Database> _abrirBaseDeDatos() async {
    // --- Paso 1: en PC (Windows) hay que activar el "motor" FFI ---
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit(); // inicializa la librería nativa de SQLite para escritorio
      databaseFactory = databaseFactoryFfi; // le dice a sqflite qué motor usar
    }

    // --- Paso 2: consigue la carpeta donde la app SÍ puede guardar archivos.
    //     Cada app tiene su carpeta privada (nadie más la lee).
    final String carpeta = await getDatabasesPath();

    // --- Paso 3: arma la ruta completa, ej: /data/.../databases/control_gasolina.db
    final String ruta = join(carpeta, _nombreBD);

    // Muestra la ruta de la BD en la consola de Flutter (solo en modo debug).
    // La verás al ejecutar: flutter run
    // Útil para saber dónde vive el archivo en tu celular o PC.
    // ignore: avoid_print
    print('┌──────────────────────────────────────────────┐');
    print('│  📁 Base de datos SQLite:                     │');
    print('│  $ruta');
    print('└──────────────────────────────────────────────┘');

    // --- Paso 4: abre la BD. Si el archivo no existe, ejecuta onCreate.
    return openDatabase(
      ruta,
      version: _version,
      onCreate: _crearTablas,
    );
  }

  /// Se ejecuta UNA sola vez en la vida de la app (cuando se crea el archivo).
  Future<void> _crearTablas(Database bd, int version) async {
    // SQL: lenguaje para hablar con bases de datos.
    // Creamos la tabla "cargas" con una columna por cada dato de nuestro modelo.
    await bd.execute('''
      CREATE TABLE cargas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        kilometraje REAL NOT NULL,
        litros REAL NOT NULL,
        costo_total REAL NOT NULL
      )
    ''');
    // AUTOINCREMENT = la base asigna 1, 2, 3... automáticamente a cada fila.
    // NOT NULL = ese dato es obligatorio.
    // REAL = número con decimales. TEXT = texto.
  }

  // --------------------------------------------------------------------------
  // OPERACIONES CRUD (Create, Read, Update, Delete)
  // --------------------------------------------------------------------------

  /// CREATE: guarda una carga nueva y regresa su id generado.
  Future<int> insertarCarga(Carga carga) async {
    final bd = await baseDeDatos;
    return bd.insert('cargas', carga.toMap());
  }

  /// READ: trae TODAS las cargas ordenadas por kilometraje (menor a mayor).
  ///
  /// ¿Por qué ordenadas así? Para calcular "km recorridos" solo necesito mirar
  /// la fila ANTERIOR en la lista: km_usados = actual - anterior.
  Future<List<Carga>> obtenerCargas() async {
    final bd = await baseDeDatos;

    // query() ejecuta un SELECT. Equivale a:
    // SELECT * FROM cargas ORDER BY kilometraje ASC
    final List<Map<String, dynamic>> filas = await bd.query(
      'cargas',
      orderBy: 'kilometraje ASC',
    );

    // Convertimos cada fila (Map) en un objeto Carga usando nuestro modelo.
    return filas.map((fila) => Carga.fromMap(fila)).toList();
  }

  /// READ (uno): busca una carga por su id. Útil para editar en el futuro.
  Future<Carga?> obtenerCarga(int id) async {
    final bd = await baseDeDatos;
    final filas = await bd.query(
      'cargas',
      where: 'id = ?', // el "?" se reemplaza de forma SEGURA por el valor
      whereArgs: [id], // (así evitamos inyección SQL)
    );
    if (filas.isEmpty) return null;
    return Carga.fromMap(filas.first);
  }

  /// UPDATE: modifica una carga existente (la identificamos por su id).
  Future<int> actualizarCarga(Carga carga) async {
    final bd = await baseDeDatos;
    return bd.update(
      'cargas',
      carga.toMap(),
      where: 'id = ?',
      whereArgs: [carga.id],
    );
  }

  /// DELETE: borra una carga por id.
  Future<int> eliminarCarga(int id) async {
    final bd = await baseDeDatos;
    return bd.delete('cargas', where: 'id = ?', whereArgs: [id]);
  }
}

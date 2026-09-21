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

import 'package:flutter/foundation.dart'; // para debugPrint
import 'package:path/path.dart'; // Une rutas de carpetas sin errores
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // API de SQLite + soporte PC

import '../models/articulo_mantenimiento.dart';
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

  /// Nombre del archivo físico donde viven tus datos.
  static const String _nombreBD = 'control_gasolina.db';

  /// Versión del esquema. Incrementada a 2 para soportar la tabla de mantenimientos.
  static const int _version = 2;

  /// Future estático de inicialización para prevenir aperturas concurrentes múltiples.
  static Future<Database>? _initFuture;

  /// Abre (o crea) la base de datos. Garantizado de ejecutarse una sola vez.
  Future<Database> get baseDeDatos {
    _initFuture ??= _abrirBaseDeDatos();
    return _initFuture!;
  }

  Future<Database> _abrirBaseDeDatos() async {
    final String carpeta = await getDatabasesPath();
    final String ruta = join(carpeta, _nombreBD);

    debugPrint('┌──────────────────────────────────────────────┐');
    debugPrint('│  📁 Base de datos SQLite:                     │');
    debugPrint('│  $ruta');
    debugPrint('└──────────────────────────────────────────────┘');

    return openDatabase(
      ruta,
      version: _version,
      onCreate: _crearTablas,
      onUpgrade: _actualizarBaseDeDatos,
    );
  }

  /// Se ejecuta UNA sola vez cuando la BD es creada por primera vez.
  Future<void> _crearTablas(Database bd, int version) async {
    await bd.execute('''
      CREATE TABLE IF NOT EXISTS cargas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        kilometraje REAL NOT NULL,
        litros REAL NOT NULL,
        costo_total REAL NOT NULL
      )
    ''');

    await _crearTablaArticulos(bd);
  }

  /// Crea la tabla articulos_mantenimiento si no existe.
  Future<void> _crearTablaArticulos(Database bd) async {
    await bd.execute('''
      CREATE TABLE IF NOT EXISTS articulos_mantenimiento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        marca TEXT NOT NULL,
        costo REAL NOT NULL,
        fecha_colocacion TEXT NOT NULL,
        kilometraje_colocacion REAL NOT NULL,
        categoria TEXT NOT NULL,
        kilometraje_vida_util REAL,
        notas TEXT
      )
    ''');
  }

  /// Se ejecuta cuando la versión de la base de datos sube de v1 a v2.
  /// Mantiene todos los datos existentes de la versión 1 sin borrar nada.
  Future<void> _actualizarBaseDeDatos(Database bd, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _crearTablaArticulos(bd);
    }
  }

  // --------------------------------------------------------------------------
  // OPERACIONES CRUD: CARGAS DE GASOLINA
  // --------------------------------------------------------------------------

  /// CREATE: guarda una carga nueva y regresa su id generado.
  Future<int> insertarCarga(Carga carga) async {
    final bd = await baseDeDatos;
    return bd.insert('cargas', carga.toMap());
  }

  /// READ: trae TODAS las cargas ordenadas por kilometraje (menor a mayor).
  Future<List<Carga>> obtenerCargas() async {
    final bd = await baseDeDatos;
    final List<Map<String, dynamic>> filas = await bd.query(
      'cargas',
      orderBy: 'kilometraje ASC',
    );
    return filas.map((fila) => Carga.fromMap(fila)).toList();
  }

  /// READ (uno): busca una carga por su id.
  Future<Carga?> obtenerCarga(int id) async {
    final bd = await baseDeDatos;
    final filas = await bd.query(
      'cargas',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (filas.isEmpty) return null;
    return Carga.fromMap(filas.first);
  }

  /// UPDATE: modifica una carga existente.
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

  /// Obtiene el kilometraje máximo registrado en las cargas de gasolina.
  Future<double> obtenerUltimoKilometrajeGasolina() async {
    final bd = await baseDeDatos;
    final result = await bd.rawQuery('SELECT MAX(kilometraje) as max_km FROM cargas');
    if (result.isNotEmpty && result.first['max_km'] != null) {
      return (result.first['max_km'] as num).toDouble();
    }
    return 0.0;
  }

  // --------------------------------------------------------------------------
  // OPERACIONES CRUD: ARTÍCULOS DE MANTENIMIENTO
  // --------------------------------------------------------------------------

  /// CREATE: Guarda un nuevo artículo de mantenimiento.
  Future<int> insertarArticulo(ArticuloMantenimiento articulo) async {
    final bd = await baseDeDatos;
    return bd.insert('articulos_mantenimiento', articulo.toMap());
  }

  /// READ: Trae artículos opcionalmente filtrados por categoría.
  Future<List<ArticuloMantenimiento>> obtenerArticulos({String? categoria}) async {
    final bd = await baseDeDatos;
    final List<Map<String, dynamic>> filas;
    if (categoria != null && categoria.isNotEmpty && categoria != 'Todos') {
      filas = await bd.query(
        'articulos_mantenimiento',
        where: 'categoria = ?',
        whereArgs: [categoria],
        orderBy: 'fecha_colocacion DESC',
      );
    } else {
      filas = await bd.query(
        'articulos_mantenimiento',
        orderBy: 'fecha_colocacion DESC',
      );
    }
    return filas.map((fila) => ArticuloMantenimiento.fromMap(fila)).toList();
  }

  /// UPDATE: Actualiza un artículo existente.
  Future<int> actualizarArticulo(ArticuloMantenimiento articulo) async {
    final bd = await baseDeDatos;
    return bd.update(
      'articulos_mantenimiento',
      articulo.toMap(),
      where: 'id = ?',
      whereArgs: [articulo.id],
    );
  }

  /// DELETE: Elimina un artículo por ID.
  Future<int> eliminarArticulo(int id) async {
    final bd = await baseDeDatos;
    return bd.delete('articulos_mantenimiento', where: 'id = ?', whereArgs: [id]);
  }
}


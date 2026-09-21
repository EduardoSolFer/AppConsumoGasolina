/// ==========================================================================
/// MODELO DE DATOS: Carga
/// ==========================================================================
/// Un "modelo" es una clase simple que representa UNA cosa de la vida real.
/// Aquí representa UNA carga de gasolina que tú haces en la gasolinera.
///
/// Este archivo NO tiene pantallas ni interfaz, solo datos y cálculos.
/// Separar los datos de la interfaz hace el código más fácil de entender
/// y de mejorar (esto se llama arquitectura).
library;

class Carga {
  // --------------------------------------------------------------------------
  // PROPIEDADES (los datos que guardamos de cada carga)
  // --------------------------------------------------------------------------

  /// Identificador único en la base de datos.
  /// Es [nullable] (puede ser null) porque cuando aún NO has guardado la carga,
  /// la base de datos todavía no le ha asignado un número.
  final int? id;

  /// Fecha en que hiciste la carga.
  final DateTime fecha;

  /// Lectura del odómetro (kilómetros totales del auto) al momento de cargar.
  final double kilometraje;

  /// Litros de gasolina que pusiste.
  final double litros;

  /// Costo total que pagaste (en tu moneda local).
  final double costoTotal;

  // --------------------------------------------------------------------------
  // CONSTRUCTOR
  // --------------------------------------------------------------------------
  /// El constructor exige TODOS los campos con `required`.
  /// Así es imposible crear una carga incompleta por accidente.
  const Carga({
    this.id,
    required this.fecha,
    required this.kilometraje,
    required this.litros,
    required this.costoTotal,
  });

  // --------------------------------------------------------------------------
  // CÁLCULOS DERIVADOS (no se guardan, se calculan al vuelo)
  // --------------------------------------------------------------------------

  /// Precio que pagaste por cada litro = costo total / litros cargados.
  double get precioPorLitro => litros > 0 ? costoTotal / litros : 0;

  /// Kilómetros recorridos desde la carga ANTERIOR hasta esta.
  ///
  /// Se necesita saber la carga anterior para poder restar kilometrajes:
  ///   km usados = odómetro actual - odómetro anterior
  ///
  /// Si [anterior] es null (es tu primera carga) devolvemos 0,
  /// porque no hay punto de comparación todavía.
  double kmRecorridos(Carga? anterior) {
    if (anterior == null) return 0;
    final km = kilometraje - anterior.kilometraje;
    return km > 0 ? km : 0; // evitamos números negativos por errores de tipeo
  }

  /// Rendimiento = kilómetros que rinde cada litro de gasolina.
  ///
  /// Fórmula: km recorridos / litros cargados.
  /// Ejemplo: recorriste 400 km con 40 litros -> rinde 10 km/litro.
  double rendimiento(Carga? anterior) {
    final km = kmRecorridos(anterior);
    if (litros <= 0 || km <= 0) return 0;
    return km / litros;
  }

  // --------------------------------------------------------------------------
  // CONVERSIÓN A/FILA DE BASE DE DATOS (SQLite solo entiende texto y números)
  // --------------------------------------------------------------------------

  /// Toma este objeto y lo convierte en un Mapa (como JSON) para guardarlo.
  factory Carga.fromMap(Map<String, dynamic> map) {
    // DateTime.parse puede fallar si el texto no es ISO8601 válido.
    // Usamos DateTime.tryParse con fallback a "ahora" para que la app no crashee.
    DateTime fecha;
    final String? fechaRaw = map['fecha'] as String?;
    // ignore: avoid_print
    print('  [BD] fecha raw = "$fechaRaw"');

    // DateTime.tryParse regresa null en vez de lanzar excepción si el
    // formato no es válido. Así evitamos que la app crashee por datos corruptos.
    if (fechaRaw != null && fechaRaw.isNotEmpty) {
      fecha = DateTime.tryParse(fechaRaw) ?? DateTime.now();
    } else {
      fecha = DateTime.now(); // fallback si la fecha es null o vacía
    }

    return Carga(
      id: map['id'] as int?,
      fecha: fecha,
      kilometraje: (map['kilometraje'] as num).toDouble(),
      litros: (map['litros'] as num).toDouble(),
      costoTotal: (map['costo_total'] as num).toDouble(),
    );
  }

  /// Convierte este objeto a Mapa para INSERTAR o ACTUALIZAR en SQLite.
  /// Nota: no incluimos 'id' porque la base de datos lo genera sola.
  Map<String, dynamic> toMap() {
    return {
      'fecha': fecha.toIso8601String(),
      'kilometraje': kilometraje,
      'litros': litros,
      'costo_total': costoTotal,
    };
  }
}

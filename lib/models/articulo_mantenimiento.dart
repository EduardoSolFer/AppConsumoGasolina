/// ==========================================================================
/// MODELO DE DATOS: ArticuloMantenimiento
/// ==========================================================================
/// Representa un artículo, repuesto o servicio de mantenimiento aplicado al vehículo
/// (ej. Afinación, Llantas, Anticongelante, Frenos, Rines, Interiores, etc.).
library;

class ArticuloMantenimiento {
  final int? id;
  final String nombre;
  final String marca;
  final double costo;
  final DateTime fechaColocacion;
  final double kilometrajeColocacion;
  final String categoria;
  final double? kilometrajeVidaUtil; // Opcional: ej. 10,000 km para afinación
  final String? notas;

  const ArticuloMantenimiento({
    this.id,
    required this.nombre,
    required this.marca,
    required this.costo,
    required this.fechaColocacion,
    required this.kilometrajeColocacion,
    required this.categoria,
    this.kilometrajeVidaUtil,
    this.notas,
  });

  /// Kilómetros recorridos desde que se instaló el artículo hasta el último
  /// registro del odómetro disponible en gasolina.
  double kmRecorridos(double ultimoKmGasolina) {
    if (ultimoKmGasolina <= kilometrajeColocacion) return 0;
    return ultimoKmGasolina - kilometrajeColocacion;
  }

  /// Porcentaje de vida útil consumido si se definió un kilometrajeVidaUtil.
  /// Devuelve un valor entre 0.0 y 1.0 (o superior a 1.0 si ya se excedió).
  double? porcentajeVidaUtil(double ultimoKmGasolina) {
    if (kilometrajeVidaUtil == null || kilometrajeVidaUtil! <= 0) return null;
    final recorridos = kmRecorridos(ultimoKmGasolina);
    return recorridos / kilometrajeVidaUtil!;
  }

  factory ArticuloMantenimiento.fromMap(Map<String, dynamic> map) {
    DateTime fecha;
    final String? fechaRaw = map['fecha_colocacion'] as String?;
    if (fechaRaw != null && fechaRaw.isNotEmpty) {
      fecha = DateTime.tryParse(fechaRaw) ?? DateTime.now();
    } else {
      fecha = DateTime.now();
    }

    return ArticuloMantenimiento(
      id: map['id'] as int?,
      nombre: map['nombre'] as String? ?? '',
      marca: map['marca'] as String? ?? '',
      costo: (map['costo'] as num?)?.toDouble() ?? 0.0,
      fechaColocacion: fecha,
      kilometrajeColocacion:
          (map['kilometraje_colocacion'] as num?)?.toDouble() ?? 0.0,
      categoria: map['categoria'] as String? ?? 'Otros',
      kilometrajeVidaUtil:
          (map['kilometraje_vida_util'] as num?)?.toDouble(),
      notas: map['notas'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      if (id != null) 'id': id,
      'nombre': nombre,
      'marca': marca,
      'costo': costo,
      'fecha_colocacion': fechaColocacion.toIso8601String(),
      'kilometraje_colocacion': kilometrajeColocacion,
      'categoria': categoria,
    };
    if (kilometrajeVidaUtil != null) map['kilometraje_vida_util'] = kilometrajeVidaUtil;
    if (notas != null && notas!.isNotEmpty) map['notas'] = notas;
    return map;
  }
}

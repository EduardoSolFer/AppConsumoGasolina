/// ==========================================================================
/// PANTALLA DE MANTENIMIENTO: Repuestos, Afinación y Registro de Artículos
/// ==========================================================================
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database_helper.dart';
import '../models/articulo_mantenimiento.dart';
import 'formulario_articulo.dart';

class PantallaMantenimiento extends StatefulWidget {
  const PantallaMantenimiento({super.key});

  @override
  State<PantallaMantenimiento> createState() => _PantallaMantenimientoState();
}

class _PantallaMantenimientoState extends State<PantallaMantenimiento> {
  final DatabaseHelper _bd = DatabaseHelper();

  List<ArticuloMantenimiento> _articulos = [];
  double _ultimoKmGasolina = 0.0;
  String _categoriaSeleccionada = 'Todos';
  bool _cargando = true;

  static const List<String> _categoriasFiltro = [
    'Todos',
    'Afinación',
    'Llantas',
    'Rines',
    'Interiores',
    'Anticongelante',
    'Frenos',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final articulos = await _bd.obtenerArticulos(
        categoria: _categoriaSeleccionada,
      );
      final ultimoKm = await _bd.obtenerUltimoKilometrajeGasolina();

      if (mounted) {
        setState(() {
          _articulos = articulos;
          _ultimoKmGasolina = ultimoKm;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _abrirFormulario({ArticuloMantenimiento? articulo}) async {
    final bool? seGuardo = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioArticulo(
          articuloEditar: articulo,
          sugerenciaKilometraje: _ultimoKmGasolina,
        ),
      ),
    );

    if (seGuardo == true) {
      _cargarDatos();
    }
  }

  Future<void> _confirmarBorrado(ArticuloMantenimiento articulo) async {
    final bool? acepto = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar artículo'),
        content: Text(
          '¿Seguro que deseas eliminar "${articulo.nombre}"? No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (acepto == true && articulo.id != null) {
      await _bd.eliminarArticulo(articulo.id!);
      await _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artículo eliminado')),
        );
      }
    }
  }

  IconData _obtenerIconoCategoria(String categoria) {
    switch (categoria) {
      case 'Afinación':
        return Icons.build;
      case 'Llantas':
        return Icons.tire_repair;
      case 'Rines':
        return Icons.circle_outlined;
      case 'Interiores':
        return Icons.chair;
      case 'Anticongelante':
        return Icons.science;
      case 'Frenos':
        return Icons.do_not_disturb_on;
      default:
        return Icons.miscellaneous_services;
    }
  }

  double get _totalInvertido =>
      _articulos.fold(0.0, (sum, art) => sum + art.costo);

  @override
  Widget build(BuildContext context) {
    final formatoMoneda = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final formatoNumero = NumberFormat('#,##0', 'es');
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          _categoriaSeleccionada == 'Todos'
              ? '🔧 Mantenimiento y Repuestos'
              : '🔧 $_categoriaSeleccionada',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  // Tarjeta Resumen
                  _buildTarjetaResumen(formatoMoneda, formatoNumero),

                  // Chips de categoría
                  _buildChipsCategorias(),

                  const SizedBox(height: 8),

                  // Lista o vista vacía
                  if (_articulos.isEmpty)
                    _buildListaVacia()
                  else
                    ..._articulos.map(
                      (art) => _buildTarjetaArticulo(
                        art,
                        formatoMoneda,
                        formatoNumero,
                        formatoFecha,
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_mantenimiento',
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar Artículo'),
      ),
    );
  }

  Widget _buildTarjetaResumen(
    NumberFormat formatoMoneda,
    NumberFormat formatoNumero,
  ) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text(
                  'Total Invertido',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  formatoMoneda.format(_totalInvertido),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            Container(height: 30, width: 1, color: Colors.grey.shade300),
            Column(
              children: [
                const Text(
                  'Último Odómetro',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatoNumero.format(_ultimoKmGasolina)} Km',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipsCategorias() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: _categoriasFiltro.map((cat) {
          final seleccionada = _categoriaSeleccionada == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              selected: seleccionada,
              label: Text(cat),
              onSelected: (bool selected) {
                setState(() {
                  _categoriaSeleccionada = cat;
                });
                _cargarDatos();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTarjetaArticulo(
    ArticuloMantenimiento art,
    NumberFormat formatoMoneda,
    NumberFormat formatoNumero,
    DateFormat formatoFecha,
  ) {
    final kmRecorridos = art.kmRecorridos(_ultimoKmGasolina);
    final porcentajeVida = art.porcentajeVidaUtil(_ultimoKmGasolina);

    Color colorVida = Colors.green;
    String estadoVidaText = 'En óptimo estado';

    if (porcentajeVida != null) {
      if (porcentajeVida >= 1.0) {
        colorVida = Colors.red;
        estadoVidaText = '¡Cambio / Servicio vencido!';
      } else if (porcentajeVida >= 0.8) {
        colorVida = Colors.orange;
        estadoVidaText = 'Próximo a cambio';
      } else if (porcentajeVida >= 0.5) {
        colorVida = Colors.blue;
        estadoVidaText = 'En uso regular';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del artículo
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    _obtenerIconoCategoria(art.categoria),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        art.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Marca: ${art.marca} • ${art.categoria}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatoMoneda.format(art.costo),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'editar') {
                      _abrirFormulario(articulo: art);
                    } else if (val == 'eliminar') {
                      _confirmarBorrado(art);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(height: 20),

            // Información de Colocación y Odómetro
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fecha: ${formatoFecha.format(art.fechaColocacion)}',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  'Instalado a: ${formatoNumero.format(art.kilometrajeColocacion)} Km',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Avance de Kilometraje acumulado
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.directions_car, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Km recorridos:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '+${formatoNumero.format(kmRecorridos)} Km',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colorVida,
                        ),
                      ),
                    ],
                  ),

                  // Si se configuró vida útil recomendada
                  if (art.kilometrajeVidaUtil != null &&
                      art.kilometrajeVidaUtil! > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (porcentajeVida ?? 0).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade300,
                        color: colorVida,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          estadoVidaText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorVida,
                          ),
                        ),
                        Text(
                          '${((porcentajeVida ?? 0) * 100).toStringAsFixed(0)}% de ${formatoNumero.format(art.kilometrajeVidaUtil)} Km',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Notas opcionales
            if (art.notas != null && art.notas!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Nota: ${art.notas}',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListaVacia() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_circle_outlined,
              size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No hay artículos registrados en esta categoría',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Presiona el botón "+ Agregar Artículo" para guardar refacciones, afinaciones, llantas y darles seguimiento.',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// ==========================================================================
/// FORMULARIO: Registrar o Editar Artículo / Mantenimiento
/// ==========================================================================
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database_helper.dart';
import '../models/articulo_mantenimiento.dart';

class FormularioArticulo extends StatefulWidget {
  final ArticuloMantenimiento? articuloEditar;
  final double sugerenciaKilometraje;

  const FormularioArticulo({
    super.key,
    this.articuloEditar,
    this.sugerenciaKilometraje = 0.0,
  });

  @override
  State<FormularioArticulo> createState() => _FormularioArticuloState();
}

class _FormularioArticuloState extends State<FormularioArticulo> {
  final _llaveFormulario = GlobalKey<FormState>();
  final _bd = DatabaseHelper();

  late TextEditingController _controlNombre;
  late TextEditingController _controlMarca;
  late TextEditingController _controlCosto;
  late TextEditingController _controlKilometrajeColocacion;
  late TextEditingController _controlVidaUtil;
  late TextEditingController _controlNotas;

  late DateTime _fechaSeleccionada;
  late String _categoriaSeleccionada;

  bool get _esEdicion => widget.articuloEditar != null;

  static const List<String> _categorias = [
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
    final art = widget.articuloEditar;

    _controlNombre = TextEditingController(text: art?.nombre ?? '');
    _controlMarca = TextEditingController(text: art?.marca ?? '');
    _controlCosto = TextEditingController(
      text: art != null ? art.costo.toStringAsFixed(2) : '',
    );
    
    final kmInicial = art?.kilometrajeColocacion ?? widget.sugerenciaKilometraje;
    _controlKilometrajeColocacion = TextEditingController(
      text: kmInicial > 0 ? kmInicial.toStringAsFixed(0) : '',
    );

    _controlVidaUtil = TextEditingController(
      text: art?.kilometrajeVidaUtil != null
          ? art!.kilometrajeVidaUtil!.toStringAsFixed(0)
          : '',
    );

    _controlNotas = TextEditingController(text: art?.notas ?? '');
    _fechaSeleccionada = art?.fechaColocacion ?? DateTime.now();

    _categoriaSeleccionada = art?.categoria ?? _categorias.first;
    if (!_categorias.contains(_categoriaSeleccionada)) {
      _categoriaSeleccionada = _categorias.first;
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_llaveFormulario.currentState!.validate()) return;

    try {
      final nombre = _controlNombre.text.trim();
      final marca = _controlMarca.text.trim();
      final costo =
          double.tryParse(_controlCosto.text.replaceAll(',', '.')) ?? 0.0;
      final kmColocacion = double.tryParse(
            _controlKilometrajeColocacion.text.replaceAll(',', '.'),
          ) ??
          0.0;

      double? vidaUtil;
      if (_controlVidaUtil.text.trim().isNotEmpty) {
        vidaUtil = double.tryParse(_controlVidaUtil.text.replaceAll(',', '.'));
      }

      final notas = _controlNotas.text.trim().isNotEmpty
          ? _controlNotas.text.trim()
          : null;

      final nuevoArticulo = ArticuloMantenimiento(
        id: widget.articuloEditar?.id,
        nombre: nombre,
        marca: marca,
        costo: costo,
        fechaColocacion: _fechaSeleccionada,
        kilometrajeColocacion: kmColocacion,
        categoria: _categoriaSeleccionada,
        kilometrajeVidaUtil: vidaUtil,
        notas: notas,
      );

      if (_esEdicion) {
        await _bd.actualizarArticulo(nuevoArticulo);
      } else {
        await _bd.insertarArticulo(nuevoArticulo);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el artículo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'Editar Artículo' : 'Nuevo Artículo / Mantenimiento',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _llaveFormulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Categoría
              DropdownButtonFormField<String>(
                initialValue: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categorias.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _categoriaSeleccionada = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Nombre del artículo
              TextFormField(
                controller: _controlNombre,
                decoration: const InputDecoration(
                  labelText: 'Nombre del artículo / servicio',
                  hintText: 'Ej. Filtro de Aceite, Bujías, Llantas traseras',
                  prefixIcon: Icon(Icons.build),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa un nombre para el artículo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Marca
              TextFormField(
                controller: _controlMarca,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  hintText: 'Ej. Castrol, Bosch, Michelin',
                  prefixIcon: Icon(Icons.sell),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa la marca del producto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Costo Total
              TextFormField(
                controller: _controlCosto,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Costo total (\$)',
                  hintText: 'Ej. 450.00',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa el costo pagado';
                  }
                  final num = double.tryParse(val.replaceAll(',', '.'));
                  if (num == null || num < 0) {
                    return 'Ingresa un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fecha de Colocación
              InkWell(
                onTap: _seleccionarFecha,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de instalación / compra',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    formatoFecha.format(_fechaSeleccionada),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Kilometraje de Instalación
              TextFormField(
                controller: _controlKilometrajeColocacion,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kilometraje en el odómetro al instalar (Km)',
                  hintText: 'Ej. 120000',
                  prefixIcon: Icon(Icons.speed),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa el kilometraje al instalar';
                  }
                  final num = double.tryParse(val.replaceAll(',', '.'));
                  if (num == null || num < 0) {
                    return 'Ingresa un kilometraje válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Vida Útil Recomendada (Km opcional)
              TextFormField(
                controller: _controlVidaUtil,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Vida útil recomendada en Km (Opcional)',
                  hintText: 'Ej. 10000 para afinación o 50000 para llantas',
                  prefixIcon: Icon(Icons.av_timer),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Notas opcionales
              TextFormField(
                controller: _controlNotas,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notas u observaciones (Opcional)',
                  hintText: 'Ej. Comprado en refaccionaria X, garantía de 6 meses',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              FilledButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.save),
                label: Text(
                  _esEdicion ? 'Actualizar Artículo' : 'Guardar Artículo',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controlNombre.dispose();
    _controlMarca.dispose();
    _controlCosto.dispose();
    _controlKilometrajeColocacion.dispose();
    _controlVidaUtil.dispose();
    _controlNotas.dispose();
    super.dispose();
  }
}

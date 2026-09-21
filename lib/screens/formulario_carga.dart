/// ==========================================================================
/// FORMULARIO: agregar una carga O editar una existente
/// ==========================================================================
/// Este mismo formulario sirve para dos cosas (modo AGREGAR y modo EDICIÓN).
/// Detecta en cuál estás según el parámetro [cargaEditar]:
///   - Si es null → estás CREANDO algo nuevo.
///   - Si trae datos → estás MODIFICANDO algo que ya existe.
///
/// Conceptos clave aquí:
///
/// 1. TextEditingController: "controlador" que maneja el texto de un campo.
///    Aquí lo usamos para LLENAR los campos con datos viejos en modo edición.
///    IMPORTANTE: siempre se destruyen en dispose() para no fugar memoria.
///
/// 2. `GlobalKey<FormState>`: permite validar TODOS los campos de golpe con
///    una sola llamada (formKey.currentState!.validate()).
///
/// 3. Navigator.pop(context, true): cierra ESTA pantalla y devuelve `true`
///    a quien la abrió, para que sepa que debe recargar los datos.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database_helper.dart';
import '../models/carga.dart';

class FormularioCarga extends StatefulWidget {
  /// Si esta carga trae datos, estamos en modo EDICIÓN.
  final Carga? cargaEditar;

  /// Odómetro del registro inmediatamente anterior (menor).
  /// Se usa para validar: el kilometraje nuevo debe ser MAYOR a este.
  final Carga? ultimaCarga;

  /// Odómetro del registro inmediatamente siguiente (mayor).
  /// Se usa en edición para validar: el kilometraje nuevo debe ser MENOR a este.
  final Carga? siguienteCarga;

  const FormularioCarga({
    super.key,
    this.cargaEditar,
    this.ultimaCarga,
    this.siguienteCarga,
  });

  @override
  State<FormularioCarga> createState() => _FormularioCargaState();
}

class _FormularioCargaState extends State<FormularioCarga> {
  // Llave global del formulario para disparar validaciones con validate().
  final _llaveFormulario = GlobalKey<FormState>();

  // Un controlador por cada campo de texto.
  final _controlKilometraje = TextEditingController();
  final _controlLitros = TextEditingController();
  final _controlCosto = TextEditingController();

  // Fecha elegida. Se inicializa con la fecha de edición o con hoy.
  late DateTime _fecha;

  // ¿Estamos en modo edición?
  bool get _esEdicion => widget.cargaEditar != null;

  // Formateador de fecha estándar.
  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

  // --------------------------------------------------------------------------
  // ESTADO INICIAL
  // --------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    if (_esEdicion) {
      // Prefill (llena) los campos con los datos viejos que el usuario
      // quiere corregir.
      _controlKilometraje.text =
          widget.cargaEditar!.kilometraje.toStringAsFixed(0);
      _controlLitros.text = widget.cargaEditar!.litros.toStringAsFixed(2);
      _controlCosto.text = widget.cargaEditar!.costoTotal.toStringAsFixed(2);
      _fecha = widget.cargaEditar!.fecha;
    } else {
      _fecha = DateTime.now(); // defaults: campos vacíos, fecha de hoy
    }
  }

  // --------------------------------------------------------------------------
  // VALIDADORES
  // --------------------------------------------------------------------------
  /// Valida que el texto sea un número mayor a cero.
  String? _validarNumeroObligatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Este dato es obligatorio';
    }
    // Reemplazamos coma por punto por si el teclado escribe "40,5".
    final numero = double.tryParse(valor.replaceAll(',', '.'));
    if (numero == null || numero <= 0) {
      return 'Escribe un número mayor a cero';
    }
    return null; // sin errores
  }

  /// Valida el kilometraje: número válido, mayor al anterior Y menor al siguiente.
  String? _validarKilometraje(String? valor) {
    // Primero las reglas básicas de cualquier número.
    final errorBasico = _validarNumeroObligatorio(valor);
    if (errorBasico != null) return errorBasico;

    final numero = double.tryParse(valor!.replaceAll(',', '.')) ?? 0.0;

    // El odómetro nunca puede ser menor o igual al registro anterior.
    final anterior = widget.ultimaCarga;
    if (anterior != null && numero <= anterior.kilometraje) {
      return 'Debe ser mayor a ${anterior.kilometraje.toStringAsFixed(0)} km';
    }

    // En modo edición, tampoco puede superar al registro siguiente.
    // (Así no rompes el orden de lecturas del odómetro).
    final siguiente = widget.siguienteCarga;
    if (siguiente != null && numero >= siguiente.kilometraje) {
      return 'Debe ser menor a ${siguiente.kilometraje.toStringAsFixed(0)} km';
    }

    return null;
  }

  // Texto que aparece debajo del campo kilometraje como ayuda.
  String get _ayudaKilometraje {
    final anterior = widget.ultimaCarga;
    final siguiente = widget.siguienteCarga;

    if (anterior != null && siguiente != null) {
      return 'Permitido: entre ${anterior.kilometraje.toStringAsFixed(0)} y '
          '${siguiente.kilometraje.toStringAsFixed(0)} km';
    }
    if (anterior != null) {
      return 'Anterior: ${anterior.kilometraje.toStringAsFixed(0)} km — escribe uno mayor';
    }
    return 'Primera carga: escribe tu odómetro actual';
  }

  // --------------------------------------------------------------------------
  // GUARDAR / ACTUALIZAR
  // --------------------------------------------------------------------------
  Future<void> _guardar() async {
    // validate() revisa TODOS los campos a la vez usando sus validators.
    if (!_llaveFormulario.currentState!.validate()) return;

    try {
      final double km =
          double.tryParse(_controlKilometraje.text.replaceAll(',', '.')) ?? 0.0;
      final double litros =
          double.tryParse(_controlLitros.text.replaceAll(',', '.')) ?? 0.0;
      final double costo =
          double.tryParse(_controlCosto.text.replaceAll(',', '.')) ?? 0.0;

      if (_esEdicion) {
        // MODO EDICIÓN: creamos un Carga con el MISMO id (para que reemplace).
        final editada = Carga(
          id: widget.cargaEditar!.id,
          fecha: _fecha,
          kilometraje: km,
          litros: litros,
          costoTotal: costo,
        );
        await DatabaseHelper().actualizarCarga(editada);
      } else {
        // MODO NUEVO: insertamos una carga completamente nueva.
        final nueva = Carga(
          fecha: _fecha,
          kilometraje: km,
          litros: litros,
          costoTotal: costo,
        );
        await DatabaseHelper().insertarCarga(nueva);
      }

      // mounted: verifica que la pantalla siga viva antes de operar sobre ella.
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la carga: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Calendario nativo para elegir fecha.
  Future<void> _elegirFecha() async {
    final DateTime? elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (elegida != null) {
      setState(() => _fecha = elegida);
    }
  }

  // --------------------------------------------------------------------------
  // INTERFAZ
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_esEdicion ? 'Editar carga' : 'Nueva carga'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _llaveFormulario,
          child: ListView(
            children: [
              // ---------- CAMPO: FECHA ----------
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: const Text('Fecha de la carga'),
                subtitle: Text(_formatoFecha.format(_fecha)),
                onTap: _elegirFecha,
                trailing: const Icon(Icons.edit_calendar),
              ),
              const SizedBox(height: 8),

              // ---------- CAMPO: KILOMETRAJE ----------
              TextFormField(
                controller: _controlKilometraje,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Kilometraje actual (odómetro)',
                  hintText: 'Ejemplo: 45230',
                  prefixIcon: const Icon(Icons.speed),
                  border: const OutlineInputBorder(),
                  helperText: _ayudaKilometraje,
                ),
                validator: _validarKilometraje,
              ),
              const SizedBox(height: 16),

              // ---------- CAMPO: LITROS ----------
              TextFormField(
                controller: _controlLitros,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Litros cargados',
                  hintText: 'Ejemplo: 40',
                  prefixIcon: Icon(Icons.local_gas_station),
                  border: OutlineInputBorder(),
                ),
                validator: _validarNumeroObligatorio,
              ),
              const SizedBox(height: 16),

              // ---------- CAMPO: COSTO TOTAL ----------
              TextFormField(
                controller: _controlCosto,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Costo total pagado',
                  hintText: 'Ejemplo: 850.00',
                  prefixIcon: Icon(Icons.payments),
                  border: OutlineInputBorder(),
                ),
                validator: _validarNumeroObligatorio,
              ),
              const SizedBox(height: 24),

              // ---------- BOTÓN: GUARDAR / ACTUALIZAR ----------
              FilledButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.save),
                label: Text(_esEdicion ? 'Guardar cambios' : 'Guardar carga'),
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
    // REGLA DE ORO: libera los controladores cuando la pantalla se cierra.
    // Evita fugas de memoria.
    _controlKilometraje.dispose();
    _controlLitros.dispose();
    _controlCosto.dispose();
    super.dispose();
  }
}

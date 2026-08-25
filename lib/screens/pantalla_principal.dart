/// ==========================================================================
/// PANTALLA PRINCIPAL (HOME): resumen de gastos + lista de cargas
/// ==========================================================================
/// Aquí aprendes 3 conceptos clave de Flutter:
///
/// 1. StatefulWidget vs StatelessWidget:
///    - StatelessWidget: pantalla que nunca cambia (solo dibuja y ya).
///    - StatefulWidget: pantalla que CAMBIA con el tiempo (aquí cargamos,
///      borramos y agregamos registros), por eso usamos Stateful.
///
/// 2. initState(): se ejecuta UNA vez, justo antes de mostrar la pantalla.
///    Es el lugar correcto para cargar datos de la base de datos.
///
/// 3. setState({}): le dice a Flutter "algo cambió, vuelve a dibujar".
///    Si actualizas una variable SIN setState, la pantalla NO se actualiza.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para dar formato bonito a las fechas

import '../data/database_helper.dart';
import '../models/carga.dart';
import 'formulario_carga.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  // Instancia única de la base de datos (patrón Singleton que vimos antes).
  final DatabaseHelper _bd = DatabaseHelper();

  // Aquí guardaremos las cargas que vienen de SQLite.
  // Empieza como lista vacía para que la pantalla pueda dibujarse de inmediato.
  List<Carga> _cargas = [];

  // Formateador de fecha: convierte DateTime -> "24/08/2026"
  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

  // --------------------------------------------------------------------------
  // CICLO DE VIDA
  // --------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _cargarCargas(); // cargamos los datos al abrir la app
  }

  /// Lee todas las cargas desde la base de datos local y refresca la pantalla.
  Future<void> _cargarCargas() async {
    final cargas = await _bd.obtenerCargas();
    // Envuelto en setState para que la lista en pantalla se redibuje.
    setState(() {
      _cargas = cargas;
    });
  }

  /// Borra una carga después de pedir confirmación al usuario.
  Future<void> _confirmarBorrado(Carga carga) async {
    // showDialog muestra una ventanita encima de todo (un AlertDialog).
    final bool? acepto = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar carga'),
        content: const Text(
          '¿Seguro que quieres eliminar este registro? No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // cierra con "false"
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // cierra con "true"
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    // Si el usuario aceptó, borramos de la BD y recargamos la lista.
    if (acepto == true && carga.id != null) {
      await _bd.eliminarCarga(carga.id!);
      await _cargarCargas();

      // SnackBar = mensajito negro que aparece abajo.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro eliminado')),
        );
      }
    }
  }

  /// Abre el formulario en modo AGREGAR.
  /// await espera a que el usuario cierre el formulario; si guardó algo
  /// devuelve true y entonces recargamos la lista.
  Future<void> _abrirFormulario() async {
    // La carga más reciente es la última de la lista (orden por kilometraje ASC).
    // La pasamos al formulario para validar que el nuevo kilometraje sea mayor.
    final Carga? ultimaCarga = _cargas.isNotEmpty ? _cargas.last : null;

    final bool? guardo = await Navigator.push<bool>(
      context,
      // MaterialPageRoute = animación estándar de pasar a otra pantalla.
      MaterialPageRoute(builder: (context) => FormularioCarga(ultimaCarga: ultimaCarga)),
    );

    if (guardo == true) await _cargarCargas();
  }

  /// Abre el formulario en modo EDICIÓN para modificar una carga existente.
  ///
  /// Le pasamos:
  ///  - la carga a editar,
  ///  - [anterior] y [siguiente]: los registros vecinos por odómetro.
  ///    Sirven para validar que, al corregir el kilometraje, no lo pongas
  ///    por debajo del anterior ni por encima del siguiente.
  Future<void> _editarCarga(Carga carga, Carga? anterior, Carga? siguiente) async {
    final bool? guardo = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioCarga(
          cargaEditar: carga,
          ultimaCarga: anterior,
          siguienteCarga: siguiente,
        ),
      ),
    );

    // Al volver, recargamos TODO desde la base de datos -> todos los cálculos
    // (km usados, rendimiento, gasto total) se recalculan automáticamente
    // con los datos ya corregidos.
    if (guardo == true) await _cargarCargas();
  }

  // --------------------------------------------------------------------------
  // CÁLCULOS DEL RESUMEN (la parte de arriba con las tarjetas verdes)
  // --------------------------------------------------------------------------

  /// Suma de TODO lo que has gastado en gasolina.
  double get _gastoTotal =>
      _cargas.fold(0, (suma, c) => suma + c.costoTotal);

  /// Kilómetros totales usados = último odómetro - primer odómetro.
  double get _kmTotales {
    if (_cargas.length < 2) return 0;
    return _cargas.last.kilometraje - _cargas.first.kilometraje;
  }

  /// Rendimiento promedio ponderado = km recorridos / litros YA CONSUMIDOS.
  ///
  /// ¿Por qué NO contamos los litros de la última carga?
  /// Porque ese gasolina todavía está en el tanque: aún no sabes cuántos
  /// kilómetros te va a rendir. Solo podemos medir un tanque cuando ya
  /// lo quemaste y vuelves a cargar.
  ///
  /// Ejemplo con 2 cargas (tu caso actual):
  ///   - Carga 1: 20 L en el odómetro 10,000
  ///   - Carga 2: 20 L en el odómetro 10,320
  ///   - Km usados = 10,320 - 10,000 = 320 km
  ///   - Litros YA gastados = solo los 20 L de la carga 1
  ///   - Rendimiento = 320 / 20 = 16 km/l  <-- correcto, no 8
  double get _rendimientoPromedio {
    if (_cargas.length < 2) return 0; // con una sola carga no hay medición

    // sublist(0, length-1) = todas las cargas MENOS la última (la más nueva).
    final litrosYaGastados = _cargas
        .sublist(0, _cargas.length - 1)
        .fold<double>(0, (suma, c) => suma + c.litros);

    if (litrosYaGastados <= 0 || _kmTotales <= 0) return 0;
    return _kmTotales / litrosYaGastados;
  }

  // --------------------------------------------------------------------------
  // INTERFAZ
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar = la barra superior con el título.
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('⛽ Control de Gasolina'),
      ),

      // FloatingActionButton = botón flotante "+" para agregar una carga.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.local_gas_station),
        label: const Text('Nueva carga'),
      ),

      body: _cargas.isEmpty
          ? // Si aún no hay registros, mostramos un mensaje amable centrado.
          const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min, // que ocupe lo justo
                children: [
                  Icon(Icons.local_gas_station, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aún no hay registros.\nToca "Nueva carga" para empezar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : // Si SÍ hay datos: resumen arriba + lista que hace scroll abajo.
          ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _tarjetasResumen(),
                // Nota aclaratoria: el rendimiento solo cuenta gasolina ya quemada.
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(
                    '* El rendimiento usa solo los litros ya consumidos '
                    '(el último tanque aún está en uso).',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 4),
                ..._construirLista(), // "..." expande la lista de widgets aquí
              ],
            ),
    );
  }

  /// Fila horizontal con 3 tarjetitas: gasto, km usados y rendimiento.
  Widget _tarjetasResumen() {
    return Row(
      children: [
        _tarjeta('Gasto total', '\$${_gastoTotal.toStringAsFixed(2)}', Icons.payments),
        const SizedBox(width: 8),
        _tarjeta('Km usados', '${_kmTotales.toStringAsFixed(1)} km', Icons.route),
        const SizedBox(width: 8),
        _tarjeta('Rendimiento', '${_rendimientoPromedio.toStringAsFixed(2)} km/l', Icons.speed),
      ],
    );
  }

  /// Una tarjetita individual del resumen (widget reutilizable: mismo diseño,
  /// distintos textos -> por eso recibe parámetros).
  Widget _tarjeta(String titulo, String valor, IconData icono) {
    return Expanded(
      // Expanded hace que las 3 tarjetas repartan el ancho por igual.
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Icon(icono, color: Colors.green.shade700),
              const SizedBox(height: 4),
              Text(titulo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              FittedBox( // encoge el número si no cabe, evita errores de overflow
                child: Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Convierte cada objeto Carga en un widget de la lista.
  List<Widget> _construirLista() {
    final List<Widget> resultado = [];

    for (int i = 0; i < _cargas.length; i++) {
      final carga = _cargas[i];
      // La carga anterior es la del índice anterior (i-1).
      // Con ella calculamos cuántos km rindió ESTE tanque.
      final Carga? anterior = i > 0 ? _cargas[i - 1] : null;
      // El vecino SIGUIENTE (odómetro mayor) existe salvo para el último
      // registro. Lo usamos al editar para no romper el orden del odómetro.
      final Carga? siguiente =
          i < _cargas.length - 1 ? _cargas[i + 1] : null;

      resultado.add(
        // Dismissible permite deslizar la tarjeta hacia un lado para borrar.
        Dismissible(
          key: Key('carga-${carga.id}'), // debe ser único por elemento
          direction: DismissDirection.endToStart, // solo de derecha a izquierda
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            // Antes de borrar pedimos confirmación.
            await _confirmarBorrado(carga);
            return false; // el borrado real lo maneja _confirmarBorrado
          },
          child: Card(
            child: ListTile(
              // Tocar la tarjeta abre el formulario en modo edición.
              onTap: () => _editarCarga(carga, anterior, siguiente),
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Text('${carga.litros.toStringAsFixed(0)}L'),
              ),
              title: Text(
                'Odómetro: ${carga.kilometraje.toStringAsFixed(0)} km',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${_formatoFecha.format(carga.fecha)} · '
                '${carga.litros.toStringAsFixed(2)} L · '
                '\$${carga.costoTotal.toStringAsFixed(2)} '
                '(\$${carga.precioPorLitro.toStringAsFixed(2)}/L)',
              ),
              // A la derecha mostramos el rendimiento SOLO si hay punto de
              // comparación (no aplica en la primera carga).
              trailing: anterior == null
                  ? const Text('—')
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${carga.rendimiento(anterior).toStringAsFixed(2)} km/l',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          '${carga.kmRecorridos(anterior).toStringAsFixed(0)} km',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    }
    return resultado;
  }
}

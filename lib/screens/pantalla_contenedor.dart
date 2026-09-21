/// ==========================================================================
/// PANTALLA CONTENEDOR: Navegación principal entre Gasolina y Mantenimiento
/// ==========================================================================
library;

import 'package:flutter/material.dart';

import 'pantalla_mantenimiento.dart';
import 'pantalla_principal.dart';

class PantallaContenedor extends StatefulWidget {
  const PantallaContenedor({super.key});

  @override
  State<PantallaContenedor> createState() => _PantallaContenedorState();
}

class _PantallaContenedorState extends State<PantallaContenedor> {
  int _indiceSeleccionado = 0;

  final List<Widget> _pantallas = const [
    PantallaPrincipal(),
    PantallaMantenimiento(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indiceSeleccionado,
        children: _pantallas,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceSeleccionado,
        onDestinationSelected: (int index) {
          setState(() {
            _indiceSeleccionado = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_gas_station_outlined),
            selectedIcon: Icon(Icons.local_gas_station),
            label: 'Gasolina',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Mantenimiento',
          ),
        ],
      ),
    );
  }
}

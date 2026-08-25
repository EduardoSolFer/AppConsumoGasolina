// ==========================================================================
// PUNTO DE ENTRADA DE LA APP
// ==========================================================================
// Todo programa Dart empieza a ejecutarse en la función main().
// En Flutter, main() casi siempre hace lo mismo: lanzar tu widget raíz
// con runApp().

import 'package:flutter/material.dart';

// Importamos nuestras propias pantallas (los archivos que creamos).
import 'screens/pantalla_principal.dart';

void main() {
  runApp(const MiAppGasolina());
}

/// El widget RAÍZ configura las cosas globales:
///  - el título de la app
///  - el tema (colores, tipografía)
///  - cuál es la PRIMERA pantalla que se muestra (home)
///
/// Es StatelessWidget porque su contenido nunca cambia por sí mismo.
class MiAppGasolina extends StatelessWidget {
  const MiAppGasolina({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Título que muestra el sistema operativo en el multitasking.
      title: 'Control de Gasolina',

      // Quita el cartelito "DEBUG" rojo de la esquina.
      debugShowCheckedModeBanner: false,

      // TEMA: define colores y estilos para TODA la app de una sola vez.
      // Cambia el seedColor y verás cambiar toda la app (¡pruébalo!).
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true, // diseño moderno de Material You
      ),

      // La primera pantalla que se ve al abrir la app.
      home: const PantallaPrincipal(),
    );
  }
}

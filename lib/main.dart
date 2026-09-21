// ==========================================================================
// PUNTO DE ENTRADA DE LA APP
// ==========================================================================
// Todo programa Dart empieza a ejecutarse en la función main().
// En Flutter, main() casi siempre hace lo mismo: lanzar tu widget raíz
// con runApp().

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // para DateFormat en español
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/pantalla_contenedor.dart';

void main() async {
  //WidgetsFlutterBinding.ensureInitialized() es OBLIGATORIO antes de llamar
  //cualquier código async dentro de main(). Sin esto, Flutter se queja.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa SQLite para escritorio (Windows, Linux, macOS)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializa los datos de formato de fecha para el idioma español.
  await initializeDateFormatting('es', null);

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
      title: 'Control de Gasolina y Mantenimiento',

      // Quita el cartelito "DEBUG" rojo de la esquina.
      debugShowCheckedModeBanner: false,

      // TEMA: define colores y estilos para TODA la app de una sola vez.
      // Cambia el seedColor y verás cambiar toda la app (¡pruébalo!).
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true, // diseño moderno de Material You
      ),

      // La primera pantalla que se ve al abrir la app.
      home: const PantallaContenedor(),
    );
  }
}


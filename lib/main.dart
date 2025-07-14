import 'package:flutter/material.dart';
import 'login_screen.dart'; // Importa la nueva pantalla de login
import 'screens/menu/comunas_screen.dart';
import 'screens/proyectos/proyecto_screen.dart';
import 'screens/vehiculos/vehiculo__screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Comunas App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _isAuthenticated
          ? HomeScreen(onLogout: () => setState(() => _isAuthenticated = false))
          : LoginScreen(
              onLoginSuccess: (success) {
                if (success) {
                  setState(() => _isAuthenticated = true);
                }
              },
            ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const HomeScreen({super.key, required this.onLogout});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    ComunasScreen(),
    ProyectoScreen(),
    VehiculoScreen(),
  ];

  final List<String> _titles = [
    'Ministerio de Comunas',
    'Proyectos',
    'Vehículos',
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menú',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Proyectos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Vehículos',
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:libcity/controllers/emprunt_controller.dart';
import 'package:libcity/views/dashboard.dart';
import 'package:libcity/views/emprunts.dart';
import 'package:libcity/views/gestion_utilisateurs.dart';
import 'package:libcity/views/historique.dart';
import 'package:libcity/views/home_page.dart';
import 'package:provider/provider.dart';
import 'views/login.dart';
import 'views/signup.dart';
import 'views/main_page.dart';
import 'views/catalogue.dart';
import 'views/evenements.dart';
import 'controllers/catalogue_controller.dart';
import 'controllers/evenement_controller.dart';
import 'controllers/user_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialisé avec succès');
    
    // Activer App Check pour le développement (évite l'erreur réseau)
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    print('✅ App Check configuré en mode debug');
    
  } catch (e) {
    print('❌ Erreur Firebase: $e');
    runApp(ErrorApp(error: e.toString()));
    return;
  }
  
  runApp(const MyApp());
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                const Text('Erreur Firebase', style: TextStyle(fontSize: 20)),
                const SizedBox(height: 10),
                Text(error, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CatalogueController()),
        ChangeNotifierProvider(create: (_) => EvenementController()),
        ChangeNotifierProvider(create: (_) => UserController()),
        ChangeNotifierProvider(create: (_) => EmpruntController()),
    
      ],
      child: MaterialApp(
        title: 'Mediacité',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignupPage(),
          '/catalogue': (context) => const CataloguePage(),
          '/evenements': (context) => const EvenementsPage(),
          '/main_page': (context) => const MainPage(),
          '/emprunts': (context) => const EmpruntsPage(),
          '/gestion_utilisateurs': (context) => const GestionUtilisateursPage(),
          '/dashboard': (context) => const DashboardPage(),
          '/historique': (context) => const HistoriquePage(),
        },
      ),
    );
  }
}
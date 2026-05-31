import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- IMPORTS DE TES ÉCRANS ---
// Remplace 'sondage' par le nom exact de ton projet (défini dans pubspec.yaml)
import 'package:sondage/screens/login_screen.dart';
import 'package:sondage/screens/survey_screen.dart';
import 'package:sondage/screens/admin_screen.dart';
import 'package:sondage/screens/teacher_screen.dart';

void main() async {
  // 1. Initialisation obligatoire pour Firebase et les Widgets
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 2. Activation de la persistance hors-ligne (Offline)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sondage Académique',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // 3. Utilisation de authStateChanges pour rester connecté (comme Facebook)
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Si on vérifie l'état de connexion
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // Si un utilisateur est déjà connecté
          if (snapshot.hasData && snapshot.data != null) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }

                // Si le profil existe dans Firestore, on redirige selon le rôle
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  String role = userSnapshot.data!['role'] ?? 'etudiant';

                  if (role == 'admin') {
                    return AdminScreen(adminId: snapshot.data!.uid);
                  } else if (role == 'enseignant') {
                    return TeacherScreen();
                  } else {
                    return SurveyScreen(userId: snapshot.data!.uid);
                  }
                }

                // Si le document n'existe pas (erreur rare)
                return LoginScreen();
              },
            );
          }

          // Si aucun utilisateur n'est connecté, on affiche le Login
          return LoginScreen();
        },
      ),
    );
  }
}
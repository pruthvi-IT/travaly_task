import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:travaly_assignment/screens/sign_in_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/hotel_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyTravalyApp());
}

class MyTravalyApp extends StatelessWidget {
  const MyTravalyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Create AuthProvider. It will be available to the whole app.
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // 2. Create HotelProvider and link it to AuthProvider.
        // This will automatically update HotelProvider whenever AuthProvider changes.
        ChangeNotifierProxyProvider<AuthProvider, HotelProvider>(
          create: (_) => HotelProvider(),
          update: (_, auth, hotel) {
            // Log to confirm the token is being passed.
            debugPrint(
              '[main] ProxyProvider updating HotelProvider. VisitorToken is: ${auth.visitorToken != null ? 'present' : 'null'}',
            );
            hotel!.updateVisitorToken(auth.visitorToken);
            return hotel;
          },
        ),
      ],
      child: MaterialApp(
        title: 'MyTravaly Hotels',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E88E5),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            // Show loading screen while device is registering
            if (auth.isDeviceRegistering) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Initializing app...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Show error if device registration failed
            if (auth.error != null && auth.visitorToken == null) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to initialize app',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          auth.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Retry device registration
                            auth.clearError();
                            // Trigger re-check which will retry registration
                            // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                            auth.notifyListeners();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Once device is registered, show appropriate screen
            return auth.isAuthenticated
                ? const HomeScreen()
                : const GoogleSignInScreen();
          },
        ),
      ),
    );
  }
}

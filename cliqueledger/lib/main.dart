
import 'package:cliqueledger/providers/Clique_list_provider.dart';
import 'package:cliqueledger/providers/transaction_provider.dart';
import 'package:cliqueledger/providers/clique_provider.dart';
import 'package:cliqueledger/providers/reports_provider.dart';
import 'package:cliqueledger/providers/clique_media_provider.dart';
import 'package:cliqueledger/providers/user_provider.dart';
import 'package:cliqueledger/service/authservice.dart';
import 'package:cliqueledger/themes/theme_provider.dart';
import 'package:cliqueledger/utility/routers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized
  
  try {
    bool isInitialized = await Authservice.instance.init(); // Await Authservice initialization
    if (!isInitialized) {
      // Handle the case where initialization fails (optional)
      //print("No refresh token");
    }
  } catch (e) {
    // Handle any exceptions thrown during initialization
    //print("Error during initialization: $e");
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CliqueProvider()),
        ChangeNotifierProvider(create: (_)=>UserProvider()),
         ChangeNotifierProvider(create: (_) => TransactionProvider()),
         ChangeNotifierProvider(create: (_) => CliqueListProvider()),
         ChangeNotifierProvider(create: (_) => ReportsProvider()),
         ChangeNotifierProvider(create: (_) => CliqueMediaProvider()),
         ChangeNotifierProvider(create:(context) => ThemeProvider(),
         child: const MyApp(),)
        // You can add other providers here as needed
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: Routers.routers(true),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
    // return MaterialApp(
    //   home: ReportListPage(),
    // );
   
  }
}

import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'home_screen.dart';
import 'create_story_screen.dart';
import 'profile_screen.dart';
import 'admin_screen.dart';
import 'users_screen.dart';
import 'user_detail_screen.dart';
import 'new_user_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

void main() {
  runApp(const StoryFundApp());
}

class StoryFundApp extends StatelessWidget {
  const StoryFundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StoryFund',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      onGenerateRoute: (RouteSettings settings) {
        Widget builder(BuildContext context) {
          switch (settings.name) {
            case '/login': return const LoginScreen();
            case '/home': return const HomeScreenV5(); // Opravené na V5 verziu s Auto-Scrollom
            case '/create_story': return const CreateStoryScreen();
            case '/profile': return const ProfileScreen();
            case '/admin': return const AdminScreen();
            case '/users': return const UsersScreen();
            case '/user_detail': return UserDetailScreen(arguments: settings.arguments);
            case '/new_user': return const NewUserScreen();
            case '/history': return const HistoryScreen();
            case '/settings': return const SettingsScreen();
            default: return const LoginScreen();
          }
        }
        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}

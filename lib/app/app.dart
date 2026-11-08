import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_theme.dart';
import 'package:flutter_proj/router/app_router.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.dependencies,
    this.initialRoute = AppRoutes.login,
    this.initialArguments,
    this.useBrandFont = true,
  });

  final MoaDependencies dependencies;
  final String initialRoute;
  final Object? initialArguments;
  final bool useBrandFont;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '모아',
      theme: AppTheme.light(useBrandFont: useBrandFont),
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(settings, dependencies),
      onGenerateInitialRoutes: (initial) {
        return [
          AppRouter.onGenerateRoute(
            RouteSettings(name: initialRoute, arguments: initialArguments),
            dependencies,
          ),
        ];
      },
    );
  }
}

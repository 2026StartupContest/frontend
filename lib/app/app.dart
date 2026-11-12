import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_proj/core/theme/app_theme.dart';
import 'package:flutter_proj/router/app_router.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';

Widget _tighterBottomSafeZone(BuildContext context, Widget? child) {
  const trim = 12.0;
  final media = MediaQuery.of(context);
  final paddingBottom = media.padding.bottom;
  final viewPaddingBottom = media.viewPadding.bottom;
  double tighten(double value) => value <= trim ? value : value - trim;
  return MediaQuery(
    data: media.copyWith(
      padding: media.padding.copyWith(bottom: tighten(paddingBottom)),
      viewPadding: media.viewPadding.copyWith(bottom: tighten(viewPaddingBottom)),
    ),
    child: child ?? const SizedBox.shrink(),
  );
}

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
      title: '모해',
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(useBrandFont: useBrandFont),
      builder: _tighterBottomSafeZone,
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

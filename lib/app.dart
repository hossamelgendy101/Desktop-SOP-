import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/sale_repository.dart';
import 'data/repositories/user_repository.dart';
import 'presentation/blocs/auth_bloc.dart';
import 'presentation/screens/login_screen.dart';
import 'services/locale_service.dart';
import 'services/theme_service.dart';

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => UserRepository()),
        RepositoryProvider(create: (_) => ProductRepository()),
        RepositoryProvider(create: (_) => SaleRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(userRepository: context.read<UserRepository>()),
          ),
        ],
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LocaleService()),
            ChangeNotifierProvider(create: (_) => ThemeService()),
          ],
          child: Builder(
            builder: (context) {
              final localeService = context.watch<LocaleService>();
              final themeService = context.watch<ThemeService>();

              return MaterialApp(
                title: 'ProPOS',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme(),
                darkTheme: AppTheme.darkTheme(),
                themeMode: themeService.themeMode,
                locale: localeService.locale,
                supportedLocales: const [
                  Locale('en'),
                  Locale('ar'),
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                builder: (context, child) {
                  return Directionality(
                    textDirection: localeService.isRTL ? TextDirection.rtl : TextDirection.ltr,
                    child: child ?? const SizedBox.shrink(),
                  );
                },
                home: const LoginScreen(),
              );
            },
          ),
        ),
      ),
    );
  }
}

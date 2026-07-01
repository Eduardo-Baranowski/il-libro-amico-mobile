import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_mobile/features/auth/login_screen.dart';
import 'package:lumina_mobile/core/theme/app_theme.dart';

void main() {
  testWidgets('Login screen exibe formulário com validações visuais', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const LoginScreen(),
          theme: ThemeData.light(),
        ),
      ),
    );

    expect(find.text('Entrar'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Criar conta de leitor'), findsOneWidget);

    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Email inválido'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
  });

  testWidgets('Tema aplica paleta Bibliotheca', (tester) async {
    final theme = AppTheme.light();

    expect(theme.colorScheme.primary, AppTheme.primary);
    expect(theme.inputDecorationTheme.fillColor, AppTheme.inputFill);
  });
}

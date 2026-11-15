import 'package:flutter/material.dart';

import '../../features/editor/presentation/screens/editor_screen.dart';
import '../../features/gallery/domain/gallery_models.dart';
import '../../features/gallery/presentation/screens/gallery_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    final screen = switch (settings.name) {
      AppRoutes.gallery => const GalleryScreen(),
      AppRoutes.editor => switch (settings.arguments) {
        PhotoSelection selection => EditorScreen(selection: selection),
        _ => const HomeScreen(),
      },
      AppRoutes.home || _ => const HomeScreen(),
    };

    return MaterialPageRoute<void>(settings: settings, builder: (_) => screen);
  }
}

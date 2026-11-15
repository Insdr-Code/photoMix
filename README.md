# PhotoMix

Aplicación móvil para crear composiciones fotográficas mediante capas, con procesamiento local en Android e iOS.

## Estado

Fase 3: motor de composición completado. El editor conserva las dimensiones originales del fondo y permite seleccionar capas, moverlas, escalarlas, rotarlas, ajustar opacidad, duplicarlas y eliminarlas. Las posiciones se almacenan con coordenadas normalizadas.

Fases anteriores: galería con permisos, álbumes, cuadrícula paginada, selección múltiple, importación de archivos y almacenamiento privado.

El plan completo está en [`docs/plan.md`](docs/plan.md).

## Desarrollo

Requisitos: Flutter 3.44.8 y Dart 3.12.2 o versiones compatibles con el SDK declarado en `pubspec.yaml`.

```sh
flutter pub get
flutter run
```

## Verificación

```sh
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
```

## Arquitectura

El código se organiza por funcionalidades (`feature-first`) dentro de `lib/features`. El tema, las constantes, los servicios y la navegación compartida están en `lib/core`. Riverpod se inicializa en `main.dart`.

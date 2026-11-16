# PhotoMix — Plan de desarrollo

**Versión:** 1.0  
**Estado:** En desarrollo — Fase 3 completada  
**Plataformas:** Android / iOS  
**Framework:** Flutter  
**Lenguaje:** Dart  
**Arquitectura:** Modular, feature-first  
**Procesamiento:** Local (on-device)

---

## 1. Descripción del proyecto

PhotoMix es una aplicación móvil multiplataforma que permite crear composiciones fotográficas mediante la superposición de múltiples imágenes sobre una fotografía principal.

El usuario podrá seleccionar fotografías de su galería, agregar elementos visuales, modificar sus propiedades, eliminar fondos, organizar capas y generar una nueva imagen.

La aplicación permitirá guardar proyectos editables y exportar las composiciones finales para compartirlas en otras aplicaciones.

## 2. Objetivos

### 2.1. Objetivo general

Desarrollar una aplicación móvil intuitiva que permita editar y combinar fotografías mediante herramientas de composición por capas, sin necesidad de utilizar servicios externos para el procesamiento principal.

### 2.2. Objetivos específicos

- Acceder a la galería de imágenes del dispositivo.
- Permitir seleccionar una fotografía como fondo principal.
- Agregar múltiples imágenes como elementos superpuestos.
- Implementar herramientas de transformación de imágenes.
- Gestionar las capas de composición.
- Eliminar fondos de fotografías mediante procesamiento local.
- Exportar composiciones en formatos PNG y JPG.
- Guardar proyectos para continuar editándolos posteriormente.
- Compartir imágenes mediante las aplicaciones instaladas en el dispositivo.

## 3. Alcance funcional del MVP

### 3.1. Gestión de fotografías

- [x] Acceder a la galería del dispositivo.
- [x] Implementar una galería personalizada.
- [x] Visualizar fotografías mediante una cuadrícula.
- [x] Navegar entre álbumes.
- [x] Seleccionar una fotografía principal.
- [x] Seleccionar imágenes adicionales.
- [x] Importar imágenes desde archivos.
- [x] Gestionar permisos de acceso a fotografías.
- [x] Copiar recursos al almacenamiento privado de PhotoMix.

### 3.2. Editor de imágenes

- [x] Crear un lienzo a partir de una fotografía.
- [x] Mantener las dimensiones y proporciones originales.
- [x] Agregar múltiples imágenes al lienzo.
- [x] Seleccionar elementos mediante interacción táctil.
- [x] Mover imágenes mediante arrastre.
- [x] Redimensionar mediante gestos multitáctiles.
- [x] Rotar imágenes.
- [x] Ajustar la opacidad.
- [x] Duplicar elementos.
- [x] Eliminar elementos.
- [ ] Bloquear y desbloquear elementos.
- [ ] Ocultar y mostrar capas.
- [ ] Deshacer operaciones.
- [ ] Rehacer operaciones.

### 3.3. Gestión de capas

- [ ] Crear un panel de capas.
- [ ] Visualizar todas las imágenes agregadas.
- [ ] Seleccionar una capa.
- [ ] Cambiar el orden de las capas.
- [ ] Enviar elementos al fondo.
- [ ] Traer elementos al frente.
- [ ] Ocultar capas.
- [ ] Bloquear capas.
- [ ] Eliminar capas.

### 3.4. Procesamiento de imágenes

- [x] Detectar dimensiones originales.
- [ ] Gestionar imágenes PNG con transparencia.
- [ ] Procesar imágenes JPG.
- [ ] Recortar imágenes.
- [ ] Aplicar máscaras de transparencia.
- [ ] Implementar eliminación automática de fondos.
- [ ] Generar imágenes con canal alfa.

La eliminación de fondos se implementará inicialmente para fotografías de personas, utilizando un modelo de segmentación ejecutado localmente.

### 3.5. Exportación

- [ ] Generar composiciones mediante un motor de renderizado independiente.
- [ ] Exportar imágenes PNG.
- [ ] Exportar imágenes JPG.
- [ ] Mantener la resolución original del lienzo.
- [ ] Permitir configurar la calidad JPG.
- [ ] Guardar imágenes en la galería.
- [ ] Compartir imágenes mediante el menú nativo del sistema operativo.

### 3.6. Gestión de proyectos

- [ ] Crear proyectos.
- [ ] Guardar proyectos editables.
- [ ] Recuperar proyectos existentes.
- [ ] Actualizar proyectos.
- [ ] Eliminar proyectos.
- [ ] Guardar referencias a las imágenes originales.
- [ ] Mantener los recursos asociados al proyecto.

---

## 4. Stack tecnológico

| Tecnología | Responsabilidad |
|---|---|
| Flutter | Desarrollo multiplataforma |
| Dart | Lenguaje de programación |
| Riverpod | Gestión de estado |
| CustomPainter | Renderizado del lienzo |
| GestureDetector | Interacciones táctiles |
| photo_manager | Acceso a la galería |
| path_provider | Almacenamiento local |
| image | Procesamiento de imágenes |
| share_plus | Compartir imágenes |
| uuid | Identificadores únicos |
| SQLite / sqflite | Persistencia de proyectos |
| TensorFlow Lite | Segmentación y eliminación de fondos |

### 4.1. Consideraciones técnicas

- El procesamiento de imágenes debe realizarse localmente.
- La interfaz debe estar desacoplada del motor de composición.
- Las operaciones pesadas deben ejecutarse fuera del hilo principal cuando sea necesario.
- El editor debe trabajar con coordenadas normalizadas.
- El renderizado final debe utilizar las dimensiones reales del lienzo.
- Los proyectos deben conservar los recursos necesarios para su recuperación.
- Se debe controlar el consumo de memoria al trabajar con imágenes de alta resolución.

---

## 5. Arquitectura del proyecto

Se utilizará una arquitectura modular basada en funcionalidades (Feature First).

```text
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   ├── theme/
│   ├── services/
│   └── utils/
│
├── features/
│   ├── home/
│   │   ├── presentation/
│   │   └── application/
│   │
│   ├── gallery/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── application/
│   │   └── presentation/
│   │
│   ├── editor/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── application/
│   │   └── presentation/
│   │       ├── screens/
│   │       ├── widgets/
│   │       ├── painters/
│   │       └── controllers/
│   │
│   ├── background_removal/
│   │   ├── data/
│   │   ├── domain/
│   │   └── application/
│   │
│   ├── export/
│   │   ├── data/
│   │   ├── domain/
│   │   └── application/
│   │
│   └── projects/
│       ├── data/
│       ├── domain/
│       └── application/
│
└── shared/
    ├── widgets/
    ├── models/
    └── extensions/
```

## 6. Modelo de datos

### 6.1. ImageLayer

Representa cada imagen agregada al lienzo.

Propiedades:

- id
- imagePath
- positionX
- positionY
- width
- height
- scale
- rotation
- opacity
- zIndex
- visible
- locked

### 6.2. EditorProject

Representa un proyecto de edición.

Propiedades:

- id
- name
- backgroundPath
- canvasWidth
- canvasHeight
- layers
- createdAt
- updatedAt

### 6.3. Persistencia

Se utilizará SQLite para almacenar metadatos de proyectos y archivos locales para almacenar las fotografías y recursos procesados.

Los proyectos podrán serializarse en JSON para facilitar su recuperación y futuras migraciones.

---

## 7. Plan de desarrollo por fases

### Fase 1. Configuración del proyecto

**Objetivo:** Preparar el entorno y establecer la estructura inicial.

Actividades:

- [x] Crear proyecto Flutter.
- [x] Configurar Android e iOS.
- [x] Instalar dependencias.
- [x] Configurar Riverpod.
- [x] Implementar tema visual.
- [x] Crear estructura modular.
- [x] Configurar navegación.
- [x] Verificar compilación en ambas plataformas.

**Entregable:** Aplicación base PhotoMix ejecutándose en Android e iOS.

**Verificación:** `flutter analyze`, `flutter test`, `flutter build apk --debug` y `flutter build ios --debug --no-codesign` completados correctamente.

### Fase 2. Galería de fotografías

**Objetivo:** Implementar la selección de imágenes.

Actividades:

- [x] Configurar permisos.
- [x] Implementar acceso a fotografías.
- [x] Crear cuadrícula de imágenes.
- [x] Implementar navegación entre álbumes.
- [x] Implementar selección de fotografía principal.
- [x] Implementar importación de imágenes adicionales.
- [x] Crear servicio de gestión de archivos.

**Entregable:** Galería personalizada funcional.

**Verificación:** `flutter analyze`, `flutter test` (10 pruebas), `flutter build apk --debug` y `flutter build ios --debug --no-codesign` completados correctamente.

### Fase 3. Motor de composición

**Objetivo:** Implementar el editor de imágenes.

Actividades:

- [x] Crear modelo ImageLayer.
- [x] Crear modelo EditorProject.
- [x] Implementar lienzo.
- [x] Implementar renderizado del fondo.
- [x] Implementar renderizado de múltiples capas.
- [x] Implementar transformación de elementos.
- [x] Implementar selección de capas.
- [x] Implementar control de posición.
- [x] Implementar escala y rotación.
- [x] Implementar opacidad.
- [x] Implementar duplicación y eliminación.

**Entregable:** Editor funcional con composición de múltiples imágenes.

**Verificación:** `flutter analyze`, `flutter test` (21 pruebas), `flutter build apk --debug` y `flutter build ios --debug --no-codesign` completados correctamente.

### Fase 4. Herramientas de edición

**Objetivo:** Mejorar la experiencia de edición.

Actividades:

- [x] Crear panel de capas.
- [x] Implementar ordenamiento de elementos.
- [x] Implementar visibilidad de capas.
- [x] Implementar bloqueo de capas.
- [x] Implementar recorte.
- [x] Implementar historial de operaciones.
- [x] Implementar Undo.
- [x] Implementar Redo.

**Entregable:** Editor con herramientas básicas completas.

**Verificación:** `flutter analyze` y `flutter test` completados correctamente.

### Fase 5. Exportación y compartir

**Objetivo:** Generar las imágenes finales.

Actividades:

- [x] Implementar motor de renderizado independiente.
- [x] Renderizar imágenes con resolución original.
- [x] Implementar exportación PNG.
- [x] Implementar exportación JPG.
- [x] Implementar configuración de calidad.
- [x] Guardar imágenes en la galería.
- [x] Implementar compartir con otras aplicaciones.
- [ ] Validar resultados en Android e iOS (Android compilado; iOS pendiente).

**Entregable:** Exportación y distribución de composiciones.

**Avance:** Renderer aislado de la UI, selector de formato/calidad, guardado en
la fototeca y menú nativo para compartir implementados.

**Verificación:** `flutter analyze`, `flutter test` y
`flutter build apk --debug` completados correctamente. La compilación
`flutter build ios --debug --no-codesign` está bloqueada porque el paquete
Swift generado de plugins declara iOS 13, pero `file-picker-darwin` requiere
iOS 14.

### Fase 6. Persistencia de proyectos

**Objetivo:** Permitir continuar trabajando sobre proyectos existentes.

Actividades:

- [ ] Configurar SQLite.
- [ ] Crear repositorio de proyectos.
- [ ] Implementar almacenamiento de recursos.
- [ ] Implementar serialización JSON.
- [ ] Guardar proyectos.
- [ ] Recuperar proyectos.
- [ ] Actualizar proyectos.
- [ ] Eliminar proyectos.
- [ ] Crear pantalla de proyectos recientes.

**Entregable:** Gestión local de proyectos editables.

### Fase 7. Eliminación de fondos

**Objetivo:** Incorporar procesamiento inteligente de imágenes.

Actividades:

- [ ] Evaluar modelo de segmentación.
- [ ] Integrar TensorFlow Lite.
- [ ] Implementar procesamiento local.
- [ ] Generar máscaras.
- [ ] Aplicar transparencia.
- [ ] Generar PNG sin fondo.
- [ ] Incorporar resultado al editor.
- [ ] Optimizar consumo de memoria.

**Entregable:** Herramienta de eliminación de fondos.

### Fase 8. Pruebas y estabilización

**Objetivo:** Preparar la aplicación para su distribución.

Actividades:

- [ ] Pruebas unitarias.
- [ ] Pruebas de widgets.
- [ ] Pruebas de integración.
- [ ] Pruebas de permisos.
- [ ] Pruebas de imágenes de alta resolución.
- [ ] Pruebas de exportación.
- [ ] Pruebas de consumo de memoria.
- [ ] Pruebas en diferentes tamaños de pantalla.
- [ ] Pruebas en Android.
- [ ] Pruebas en iOS.
- [ ] Corrección de errores.
- [ ] Preparación de versiones de distribución.

**Entregable:** PhotoMix 1.0 estable.

---

## 8. Diseño de interfaz

Se utilizará un diseño minimalista y moderno.

### Pantallas principales

1. Home: inicio y proyectos recientes.
2. Gallery: selector personalizado de fotografías.
3. Editor: lienzo de composición.
4. Layers: administración de elementos.
5. Export: configuración y previsualización.
6. Projects: proyectos guardados.

### Lineamientos visuales

- Fondo principal: #F8F8FC.
- Color primario: #7057E8.
- Superficies: #FFFFFF.
- Texto principal: #20202A.
- Texto secundario: #858593.
- Bordes redondeados.
- Iconografía minimalista.
- Diseño adaptable a Android e iOS.

---

## 9. Pruebas y criterios de aceptación

| Funcionalidad | Criterio de aceptación |
|---|---|
| Galería | Permite consultar y seleccionar fotografías |
| Fondo | Conserva las proporciones originales |
| Superposición | Permite agregar varias imágenes |
| Movimiento | Permite posicionar elementos |
| Escala | Permite ampliar y reducir imágenes |
| Rotación | Permite rotar elementos |
| Opacidad | Permite ajustar transparencia |
| Capas | Permite modificar el orden |
| Undo/Redo | Permite recuperar estados anteriores |
| Persistencia | Permite recuperar proyectos |
| Exportación | Genera archivos PNG y JPG válidos |
| Compartir | Abre el menú nativo de compartir |
| Eliminación de fondos | Genera una imagen con transparencia |

---

## 10. Consideraciones de rendimiento

- Utilizar miniaturas para la galería.
- Cargar imágenes bajo demanda.
- Evitar decodificar repetidamente los mismos recursos.
- Mantener las imágenes originales separadas de las previsualizaciones.
- Implementar caché de imágenes.
- Ejecutar procesamiento pesado en isolates cuando sea apropiado.
- Controlar el tamaño de los buffers de memoria.
- Liberar recursos gráficos después de exportar.
- Evitar capturas de pantalla para generar composiciones finales.

## 11. Alcance futuro: versiones posteriores

Las siguientes funcionalidades quedan fuera del MVP inicial.

### PhotoMix 1.1

- Filtros fotográficos.
- Ajustes de brillo y contraste.
- Texto sobre imágenes.
- Stickers.
- Marcos.
- Plantillas de composición.

### PhotoMix 1.2

- Segmentación de animales y objetos.
- Recorte inteligente.
- Herramientas avanzadas de selección.
- Eliminación de objetos.

### PhotoMix 2.0

- Registro de usuarios.
- Sincronización en la nube.
- Almacenamiento remoto de proyectos.
- Plantillas compartidas.
- Biblioteca de recursos.
- Funcionalidades de inteligencia artificial adicionales.

---

## 12. Orden de implementación recomendado

El desarrollo debe seguir este orden para evitar construir funcionalidades sobre componentes todavía inestables:

1. Configuración del proyecto.
2. Galería personalizada.
3. Selección de imagen de fondo.
4. Lienzo con dimensiones originales.
5. Agregar imágenes superpuestas.
6. Transformaciones y gestos.
7. Gestión de capas.
8. Historial Undo/Redo.
9. Motor de exportación.
10. Persistencia de proyectos.
11. Compartir imágenes.
12. Eliminación de fondos.
13. Pruebas y estabilización.

## 13. Definición de terminado del MVP

PhotoMix 1.0 se considerará terminado cuando:

- Funcione en Android y iOS.
- Permita seleccionar fotografías de la galería.
- Permita crear composiciones con múltiples imágenes.
- Permita editar las imágenes individualmente.
- Permita administrar las capas.
- Incluya Undo y Redo.
- Permita guardar y recuperar proyectos.
- Permita exportar PNG y JPG.
- Mantenga la resolución del lienzo.
- Permita compartir imágenes.
- Incluya eliminación de fondos de personas.
- Supere las pruebas funcionales y de estabilidad.

**Resultado esperado:** una aplicación móvil independiente, funcional y multiplataforma para crear composiciones fotográficas mediante una interfaz sencilla, con procesamiento local y capacidad de guardar y compartir los resultados.
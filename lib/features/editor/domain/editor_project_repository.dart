import 'editor_project.dart';

abstract interface class EditorProjectRepository {
  Future<void> save(EditorProject project);

  Future<EditorProject?> getById(String id);

  Future<List<EditorProject>> getRecent({int limit = 20});

  Future<void> delete(String id);
}

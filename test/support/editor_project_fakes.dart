import 'package:photmix_app/features/editor/domain/editor_project.dart';
import 'package:photmix_app/features/editor/domain/editor_project_repository.dart';

class FakeEditorProjectRepository implements EditorProjectRepository {
  final projects = <String, EditorProject>{};
  Object? failure;

  @override
  Future<void> save(EditorProject project) async {
    if (failure case final error?) throw error;
    projects[project.id] = project;
  }

  @override
  Future<EditorProject?> getById(String id) async {
    if (failure case final error?) throw error;
    return projects[id];
  }

  @override
  Future<List<EditorProject>> getRecent({int limit = 20}) async {
    if (failure case final error?) throw error;
    final recent = projects.values.toList()
      ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    return recent.take(limit).toList(growable: false);
  }

  @override
  Future<void> delete(String id) async {
    if (failure case final error?) throw error;
    projects.remove(id);
  }
}

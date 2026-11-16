import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/editor_project.dart';
import '../domain/editor_project_repository.dart';
import 'editor_project_json_codec.dart';

class SqfliteEditorProjectRepository implements EditorProjectRepository {
  Future<Database>? _database;

  Future<Database> get _db => _database ??= _openDatabase();

  @override
  Future<void> save(EditorProject project) async {
    final database = await _db;
    await database.insert(
      'editor_projects',
      EditorProjectJsonCodec.projectToRow(project),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<EditorProject?> getById(String id) async {
    final database = await _db;
    final rows = await database.query(
      'editor_projects',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return EditorProjectJsonCodec.projectFromRow(rows.single);
  }

  @override
  Future<List<EditorProject>> getRecent({int limit = 20}) async {
    if (limit < 1) throw RangeError.range(limit, 1, null, 'limit');
    final database = await _db;
    final rows = await database.query(
      'editor_projects',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return rows
        .map(EditorProjectJsonCodec.projectFromRow)
        .toList(growable: false);
  }

  @override
  Future<void> delete(String id) async {
    final database = await _db;
    await database.delete('editor_projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<Database> _openDatabase() async {
    final documents = await getApplicationDocumentsDirectory();
    final databasePath = p.join(documents.path, 'PhotoMix', 'projects.db');
    await Directory(p.dirname(databasePath)).create(recursive: true);
    return openDatabase(
      databasePath,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE editor_projects (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            background_path TEXT NOT NULL,
            canvas_width INTEGER NOT NULL,
            canvas_height INTEGER NOT NULL,
            layers_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await database.execute(
          'CREATE INDEX editor_projects_updated_at '
          'ON editor_projects(updated_at DESC)',
        );
      },
    );
  }
}

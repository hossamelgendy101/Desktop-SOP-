import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  Future<String> createBackup() async {
    final dbDir = await getApplicationDocumentsDirectory();
    final dbPath = join(dbDir.path, 'pos_system.db');
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('Database not found');
    }

    final backupDir = Directory(join(dbDir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupFileName = 'pos_backup_\$timestamp.zip';
    final backupPath = join(backupDir.path, backupFileName);

    final archive = Archive();
    final dbBytes = await dbFile.readAsBytes();
    archive.addFile(ArchiveFile('pos_system.db', dbBytes.length, dbBytes));

    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);
    if (zipData != null) {
      await File(backupPath).writeAsBytes(zipData);
    }

    return backupPath;
  }

  Future<void> shareBackup(String path) async {
    await Share.shareXFiles([XFile(path)], text: 'POS System Backup');
  }

  Future<void> restoreBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'db'],
    );

    if (result == null || result.files.single.path == null) return;

    final pickedFile = File(result.files.single.path!);
    final dbDir = await getApplicationDocumentsDirectory();
    final dbPath = join(dbDir.path, 'pos_system.db');

    if (result.files.single.extension == 'zip') {
      final bytes = await pickedFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (file.name.endsWith('.db')) {
          final restoredDb = File(dbPath);
          await restoredDb.writeAsBytes(file.content as List<int>);
          break;
        }
      }
    } else {
      await pickedFile.copy(dbPath);
    }
  }

  Future<List<FileSystemEntity>> listBackups() async {
    final dbDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(join(dbDir.path, 'backups'));
    if (!await backupDir.exists()) return [];
    return backupDir.listSync().where((f) => f.path.endsWith('.zip')).toList();
  }
}

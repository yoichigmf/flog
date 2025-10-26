import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// メディアタイプを定義
enum MediaType {
  audio,
  image,
  video,
}

// 活動ログテーブル
class ActivityLogs extends Table {
  // 主キー
  IntColumn get id => integer().autoIncrement()();

  // テキストコンテンツ（すべてのログで使用可能）
  TextColumn get textContent => text().nullable()();

  // メディアタイプ（audio, image, video、メディアがない場合はnull）
  TextColumn get mediaType => text().nullable()();

  // メディアファイル名（メディアがある場合のみ）
  TextColumn get fileName => text().nullable()();

  // 緯度
  RealColumn get latitude => real().nullable()();

  // 経度
  RealColumn get longitude => real().nullable()();

  // 登録時刻
  DateTimeColumn get createdAt => dateTime()();
}

// データベースクラス
@DriftDatabase(tables: [ActivityLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  // スキーマ変更時のマイグレーション処理
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // バージョン2へのマイグレーション：既存データをクリア
          await m.deleteTable('activity_logs');
          await m.createTable(activityLogs);
        }
      },
    );
  }

  // ログを追加
  Future<int> addLog({
    String? textContent,
    MediaType? mediaType,
    String? fileName,
    double? latitude,
    double? longitude,
  }) {
    return into(activityLogs).insert(
      ActivityLogsCompanion.insert(
        textContent: Value(textContent),
        mediaType: Value(mediaType?.name),
        fileName: Value(fileName),
        latitude: Value(latitude),
        longitude: Value(longitude),
        createdAt: DateTime.now(),
      ),
    );
  }

  // すべてのログを取得（新しい順）
  Future<List<ActivityLog>> getAllLogs() {
    return (select(activityLogs)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // IDでログを取得
  Future<ActivityLog?> getLogById(int id) {
    return (select(activityLogs)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // ログを削除
  Future<int> deleteLog(int id) {
    return (delete(activityLogs)..where((t) => t.id.equals(id))).go();
  }

  // 特定のメディアタイプのログを取得
  Future<List<ActivityLog>> getLogsByMediaType(MediaType type) {
    return (select(activityLogs)
          ..where((t) => t.mediaType.equals(type.name))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // テキストのみのログを取得
  Future<List<ActivityLog>> getTextOnlyLogs() {
    return (select(activityLogs)
          ..where((t) => t.mediaType.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // ログを更新
  Future<bool> updateLog(ActivityLog log) {
    return update(activityLogs).replace(log);
  }
}

// データベース接続を開く
QueryExecutor _openConnection() {
  return driftDatabase(name: 'activity_logs_db');
}

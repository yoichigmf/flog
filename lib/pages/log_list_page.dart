import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../services/file_service.dart';
import 'add_log_page.dart';
import 'log_detail_page.dart';

class LogListPage extends StatefulWidget {
  final AppDatabase database;

  const LogListPage({super.key, required this.database});

  @override
  State<LogListPage> createState() => _LogListPageState();
}

class _LogListPageState extends State<LogListPage> {
  List<ActivityLog> _logs = [];
  bool _isLoading = true;
  MediaType? _filterType;
  bool _showTextOnly = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  // ログを読み込む
  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<ActivityLog> logs;

      if (_showTextOnly) {
        logs = await widget.database.getTextOnlyLogs();
      } else if (_filterType != null) {
        logs = await widget.database.getLogsByMediaType(_filterType!);
      } else {
        logs = await widget.database.getAllLogs();
      }

      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログの読み込みエラー: $e')),
        );
      }
    }
  }

  // ログを削除
  Future<void> _deleteLog(ActivityLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('このログを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // ファイルがある場合は削除
        if (log.fileName != null) {
          await FileService.deleteFile(log.fileName!);
        }

        // データベースから削除
        await widget.database.deleteLog(log.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ログを削除しました')),
          );
          _loadLogs();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('削除エラー: $e')),
          );
        }
      }
    }
  }

  // メディアタイプのアイコンを取得
  IconData? _getMediaTypeIcon(String? mediaType) {
    if (mediaType == null) return null;

    switch (mediaType) {
      case 'audio':
        return Icons.audiotrack;
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      default:
        return null;
    }
  }

  // メディアタイプの色を取得
  Color _getMediaTypeColor(String? mediaType) {
    if (mediaType == null) return Colors.blue;

    switch (mediaType) {
      case 'audio':
        return Colors.orange;
      case 'image':
        return Colors.green;
      case 'video':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // メディアタイプの表示名を取得
  String _getMediaTypeName(String? mediaType) {
    if (mediaType == null) return 'テキストのみ';

    switch (mediaType) {
      case 'audio':
        return '音声付き';
      case 'image':
        return '画像付き';
      case 'video':
        return '動画付き';
      default:
        return 'テキストのみ';
    }
  }

  // フィルターメニューを表示
  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('すべて表示'),
              onTap: () {
                setState(() {
                  _filterType = null;
                  _showTextOnly = false;
                });
                Navigator.pop(context);
                _loadLogs();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.text_fields, color: Colors.blue),
              title: const Text('テキストのみ'),
              onTap: () {
                setState(() {
                  _filterType = null;
                  _showTextOnly = true;
                });
                Navigator.pop(context);
                _loadLogs();
              },
            ),
            ListTile(
              leading: Icon(Icons.audiotrack,
                  color: _getMediaTypeColor('audio')),
              title: const Text('音声付きのみ'),
              onTap: () {
                setState(() {
                  _filterType = MediaType.audio;
                  _showTextOnly = false;
                });
                Navigator.pop(context);
                _loadLogs();
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.image, color: _getMediaTypeColor('image')),
              title: const Text('画像付きのみ'),
              onTap: () {
                setState(() {
                  _filterType = MediaType.image;
                  _showTextOnly = false;
                });
                Navigator.pop(context);
                _loadLogs();
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.videocam, color: _getMediaTypeColor('video')),
              title: const Text('動画付きのみ'),
              onTap: () {
                setState(() {
                  _filterType = MediaType.video;
                  _showTextOnly = false;
                });
                Navigator.pop(context);
                _loadLogs();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('活動ログ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterMenu,
            tooltip: 'フィルター',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: '更新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filterType != null || _showTextOnly
                            ? '該当するログがありません'
                            : 'ログがまだありません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '右下の + ボタンから追加できます',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
                    final mediaIcon = _getMediaTypeIcon(log.mediaType);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _getMediaTypeColor(log.mediaType),
                          child: Icon(
                            mediaIcon ?? Icons.text_fields,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          log.textContent != null && log.textContent!.isNotEmpty
                              ? log.textContent!
                              : _getMediaTypeName(log.mediaType),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (log.mediaType != null)
                              Row(
                                children: [
                                  Icon(mediaIcon, size: 14),
                                  const SizedBox(width: 4),
                                  Text(_getMediaTypeName(log.mediaType)),
                                ],
                              ),
                            Text(
                              dateFormat.format(log.createdAt),
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (log.latitude != null && log.longitude != null)
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 12),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${log.latitude!.toStringAsFixed(4)}, ${log.longitude!.toStringAsFixed(4)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteLog(log),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => LogDetailPage(log: log),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddLogPage(database: widget.database),
            ),
          );

          if (result == true) {
            _loadLogs();
          }
        },
        tooltip: 'ログを追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/database.dart';
import '../services/file_service.dart';
import '../services/location_service.dart';

class LogDetailPage extends StatefulWidget {
  final ActivityLog log;

  const LogDetailPage({super.key, required this.log});

  @override
  State<LogDetailPage> createState() => _LogDetailPageState();
}

class _LogDetailPageState extends State<LogDetailPage> {
  File? _mediaFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMediaFile();
  }

  // メディアファイルを読み込む
  Future<void> _loadMediaFile() async {
    if (widget.log.fileName != null) {
      final file = await FileService.getFile(widget.log.fileName!);
      if (mounted) {
        setState(() {
          _mediaFile = file;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Google Mapsで位置を開く
  Future<void> _openInMaps() async {
    if (widget.log.latitude != null && widget.log.longitude != null) {
      final location = LocationData(
        latitude: widget.log.latitude!,
        longitude: widget.log.longitude!,
      );
      final url = location.toGoogleMapsUrl();
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('マップを開けませんでした')),
          );
        }
      }
    }
  }

  // メディアタイプの表示名を取得
  String _getMediaTypeName(String? mediaType) {
    if (mediaType == null) return 'テキストのみ';

    switch (mediaType) {
      case 'audio':
        return '音声';
      case 'image':
        return '画像';
      case 'video':
        return '動画';
      default:
        return 'テキストのみ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: const Text('ログ詳細'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 登録日時
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '登録日時',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dateFormat.format(widget.log.createdAt),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // テキストコンテンツ
                  if (widget.log.textContent != null &&
                      widget.log.textContent!.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'テキスト',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.log.textContent!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (widget.log.textContent != null &&
                      widget.log.textContent!.isNotEmpty)
                    const SizedBox(height: 16),

                  // メディアコンテンツ
                  if (widget.log.mediaType != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  widget.log.mediaType == 'audio'
                                      ? Icons.audiotrack
                                      : widget.log.mediaType == 'image'
                                          ? Icons.image
                                          : Icons.videocam,
                                  color: widget.log.mediaType == 'audio'
                                      ? Colors.orange
                                      : widget.log.mediaType == 'image'
                                          ? Colors.green
                                          : Colors.purple,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getMediaTypeName(widget.log.mediaType),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_mediaFile != null) ...[
                              if (widget.log.mediaType == 'image') ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _mediaFile!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              Text(
                                'ファイル名: ${widget.log.fileName}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              FutureBuilder<int?>(
                                future: FileService.getFileSize(
                                    widget.log.fileName!),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    return Text(
                                      'サイズ: ${FileService.formatFileSize(snapshot.data!)}',
                                      style: const TextStyle(fontSize: 14),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ] else
                              const Text('ファイルが見つかりません'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 位置情報
                  if (widget.log.latitude != null &&
                      widget.log.longitude != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '位置情報',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '緯度: ${widget.log.latitude!.toStringAsFixed(6)}\n経度: ${widget.log.longitude!.toStringAsFixed(6)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _openInMaps,
                              icon: const Icon(Icons.map),
                              label: const Text('Google Mapsで開く'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '位置情報',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '位置情報が記録されていません',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

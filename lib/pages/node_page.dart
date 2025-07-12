import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

// 定义主题颜色 - 语雀风格配色（优化对比度）
class AppTheme {
  // 主色调
  static const Color primary = Color(0xFF25B07B); // 语雀绿（稍微加深）
  static const Color secondary = Color(0xFF5B67CA); // 紫蓝色

  // 中性色
  static const Color background = Color(0xFFF7F9FA); // 背景色
  static const Color cardBackground = Color(0xFFFFFFFF); // 卡片背景
  static const Color divider = Color(0xFFEEF1F4); // 分割线

  // 文字颜色（提高对比度）
  static const Color textPrimary = Color(0xFF222222); // 主要文字（加深）
  static const Color textSecondary = Color(0xFF555555); // 次要文字（加深）
  static const Color textHint = Color(0xFF888888); // 提示文字（加深）

  // 便签主题颜色（优化对比度）
  // 便签主题颜色（优化对比度 + 增加种类）
  static const Map<String, Color> noteThemes = {
    'default': Color(0xFFE8F5F0), // 淡绿
    'blue': Color(0xFFECF2FC), // 淡蓝
    'purple': Color(0xFFF3ECF8), // 淡紫
    'yellow': Color(0xFFFFF6E0), // 淡黄
    'pink': Color(0xFFFFECF0), // 淡粉
    // 新增
    'teal': Color(0xFFE0F7F9), // 薄荷青
    'orange': Color(0xFFFFEDE0), // 奶橘
    'olive': Color(0xFFF2F5E5), // 雅灰绿
    'gray': Color(0xFFF3F4F6), // 云雾灰（适合作为默认）
    'indigo': Color(0xFFE8EAFD), // 静谧蓝紫
    'red': Color(0xFFFDECEC), // 雪白淡红
    'sky': Color(0xFFE5F6FD), // 天空蓝
  };

  // 便签主题名称
  static const Map<String, String> themeNames = {
    'default': '清新绿',
    'blue': '天空蓝',
    'purple': '梦幻紫',
    'yellow': '暖阳黄',
    'pink': '浪漫粉',
  };
}

class Note {
  final String id;
  String title;
  String content;
  List<String> images;
  String? audioPath;
  DateTime createdAt;
  DateTime updatedAt;
  String theme;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.images,
    this.audioPath,
    required this.createdAt,
    required this.updatedAt,
    required this.theme,
  });

  factory Note.create() {
    return Note(
      id: DateTime
          .now()
          .millisecondsSinceEpoch
          .toString(),
      title: '',
      content: '',
      images: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      theme: 'default',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'images': images,
      'audioPath': audioPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'theme': theme,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      images: List<String>.from(json['images']),
      audioPath: json['audioPath'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      theme: json['theme'],
    );
  }
}

class NodePage extends StatefulWidget {
  const NodePage({super.key});

  @override
  State<NodePage> createState() => _NodePageState();
}

class _NodePageState extends State<NodePage> {
  List<Note> notes = [];

  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  String _currentTheme = 'default';
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.closePlayer();
    _searchController.dispose();
    super.dispose();
  }

  // 在 _NodePageState 类中添加以下方法

  // 检查悬浮窗权限
  Future<bool> _checkFloatingPermission() async {
    bool hasPermission = await FlutterOverlayWindow.isPermissionGranted();
    if (!hasPermission) {
      // 显示权限请求对话框
      bool? userChoice = await showDialog<bool>(
        context: context,
        builder:
            (context) =>
            AlertDialog(
              title: const Text('需要悬浮窗权限'),
              content: const Text('显示悬浮便签需要悬浮窗权限，是否授权？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('授权'),
                ),
              ],
            ),
      );

      if (userChoice == true) {
        // 请求权限
        await FlutterOverlayWindow.requestPermission();
        return await FlutterOverlayWindow.isPermissionGranted();
      }
      return false;
    }
    return true;
  }

  Future<void> _toggleFloatingNote(Note note) async {
    try {
      // 检查是否已有悬浮窗
      bool isActive = await FlutterOverlayWindow.isActive();
      print('悬浮窗是否已激活: $isActive');

      if (isActive) {
        // 关闭悬浮窗
        await FlutterOverlayWindow.closeOverlay();
        return;
      }

      // 没有悬浮窗，检查权限
      bool hasPermission = await _checkFloatingPermission();
      print('悬浮窗权限: $hasPermission');
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('需要悬浮窗权限才能显示悬浮便签'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // 保存当前便签数据到临时存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('floating_note', jsonEncode(note.toJson()));
      print("准备打开悬浮窗...");

      // 打开悬浮窗 - 使用try-catch捕获可能的错误
      try {
       await FlutterOverlayWindow.showOverlay(
          height: 300,
          width: 300,
          alignment: OverlayAlignment.center,
          enableDrag: true,
          flag: OverlayFlag.defaultFlag,
          visibility: NotificationVisibility.visibilityPublic,
        );

      } catch (e) {
        print("打开悬浮窗出错: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('悬浮窗打开失败: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print("悬浮窗操作出错: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('悬浮窗操作失败: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _initAudioPlayer() async {
    await _audioPlayer.openPlayer();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString('notes');
    if (notesJson != null) {
      final List<dynamic> decoded = json.decode(notesJson);
      setState(() {
        notes = decoded.map((item) => Note.fromJson(item)).toList();
        // 按创建时间排序，最新的在前面
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(notes.map((note) => note.toJson()).toList());
    await prefs.setString('notes', encoded);
  }

  Future<void> _addNote() async {
    final note = Note.create();
    note.theme = _currentTheme;

    await _editNote(note, isNew: true);
  }

  Future<void> _editNote(Note note, {bool isNew = false}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditorPage(note: note)),
    );

    if (result == true) {
      setState(() {
        if (isNew) {
          notes.insert(0, note); // 添加到列表开头
        }
        // 更新时间
        note.updatedAt = DateTime.now();
        // 重新排序
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
      await _saveNotes();
    }
  }

  void _deleteNote(Note note) {
    showDialog(
      context: context,
      builder:
          (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              '删除便签',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            content: const Text(
              '确定要删除这个便签吗？',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '取消',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() {
                    notes.remove(note);
                  });
                  await _saveNotes();

                  // 删除相关的音频文件
                  if (note.audioPath != null) {
                    final file = File(note.audioPath!);
                    if (await file.exists()) {
                      await file.delete();
                    }
                  }
                },
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _changeTheme(String theme) {
    setState(() {
      _currentTheme = theme;
    });
  }

  List<Note> _getFilteredNotes() {
    if (_searchQuery.isEmpty) {
      return notes;
    }
    return notes.where((note) {
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _getRandomThemeKey() {
    final keys = AppTheme.noteThemes.keys.toList();
    keys.remove('default'); // 可选：不随机到默认色
    keys.shuffle();
    return keys.first;
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = _getFilteredNotes();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title:
        _isSearching
            ? TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '搜索便签...',
            hintStyle: const TextStyle(color: AppTheme.textHint),
            border: InputBorder.none,
            prefixIcon: const Icon(
              Icons.search,
              color: AppTheme.textHint,
            ),
          ),
          style: const TextStyle(color: AppTheme.textPrimary),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        )
            : const Text(
          '我的便签',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: AppTheme.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),

          // PopupMenuButton<String>(
          //   icon: const Icon(Icons.color_lens, color: AppTheme.textSecondary),
          //   onSelected: _changeTheme,
          //   itemBuilder:
          //       (context) =>
          //           AppTheme.themeNames.entries.map((entry) {
          //             return PopupMenuItem(
          //               value: entry.key,
          //               child: Row(
          //                 children: [
          //                   Container(
          //                     width: 16,
          //                     height: 16,
          //                     decoration: BoxDecoration(
          //                       color: AppTheme.noteThemes[entry.key],
          //                       borderRadius: BorderRadius.circular(4),
          //                     ),
          //                   ),
          //                   const SizedBox(width: 8),
          //                   Text(entry.value),
          //                 ],
          //               ),
          //             );
          //           }).toList(),
          // ),
        ],
      ),
      body:
      filteredNotes.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: AppTheme.noteThemes[_currentTheme],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? '暂无便签，点击右下角添加吧~'
                  : '没有找到匹配的便签',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadNotes,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            itemCount: filteredNotes.length,
            itemBuilder: (context, index) {
              final note = filteredNotes[index];
              return _buildNoteCard(note);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        // ✅ 关闭默认 Hero tag，避免冲突
        onPressed: _addNote,
        backgroundColor: AppTheme.primary,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final themeKey = note.theme ?? _getRandomThemeKey();
    final themeColor =
        AppTheme.noteThemes[themeKey] ?? AppTheme.noteThemes['default'];
    return GestureDetector(
      onTap: () => _editNote(note),
      child: Card(
        elevation: 0,
        color: themeColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.divider, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (note.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    note.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (note.images.isNotEmpty)
                Container(
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                      note.images.length > 3 ? 3 : note.images.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            // 添加图片预览功能
                            _showImagePreview(context, note.images, index);
                          },
                          child: Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(File(note.images[index])),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child:
                            index == 2 && note.images.length > 3
                                ? Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.black.withOpacity(0.5),
                              ),
                              child: Center(
                                child: Text(
                                  '+${note.images.length - 3}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (note.audioPath != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.audiotrack,
                        color: AppTheme.secondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '语音备忘录',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${note.updatedAt.year}/${note.updatedAt.month}/${note
                        .updatedAt.day}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textHint,
                    ),
                  ),

                  // 添加悬浮窗按钮
                  GestureDetector(
                    onTap: () => _toggleFloatingNote(note),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.picture_in_picture_alt,
                        size: 18,
                        color: AppTheme.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppTheme.textHint,
                    ),
                    onPressed: () => _deleteNote(note),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 新增：图片预览功能
  void _showImagePreview(BuildContext context,
      List<String> images,
      int initialIndex,) {
    showDialog(
      context: context,
      builder:
          (context) =>
          Dialog.fullscreen(
            child: ImagePreviewPage(images: images, initialIndex: initialIndex),
          ),
    );
  }
}

// 新增：图片预览页面
class ImagePreviewPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImagePreviewPage({
    required this.images,
    required this.initialIndex,
    super.key,
  });

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1}/${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            child: Center(
              child: Image.file(
                File(widget.images[index]),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

// 录音计时器类
class RecordingTimer {
  Timer? _timer;
  int _seconds = 0;
  final Function(int) onTick;

  RecordingTimer({required this.onTick});

  void start() {
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds++;
      onTick(_seconds);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _seconds = 0;
  }

  String get formattedTime {
    final minutes = (_seconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get isRunning => _timer != null;
}

class NoteEditorPage extends StatefulWidget {
  final Note note;

  const NoteEditorPage({required this.note, super.key});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();

  // 更新为 record 6.0.0 兼容的录音实现
  // final Record _audioRecorder = Record();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  late RecordingTimer _recordingTimer;
  String _recordingTime = '00:00';

  // 录音波形动画值
  final List<double> _waveformValues = [0.3, 0.7, 0.5, 0.9, 0.4, 0.8, 0.6];
  int _waveformIndex = 0;
  Timer? _waveformTimer;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.note.title;
    _contentController.text = widget.note.content;
    _initAudioPlayer();
    _recordingTimer = RecordingTimer(
      onTick: (seconds) {
        setState(() {
          _recordingTime = _recordingTimer.formattedTime;
        });
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _audioPlayer.closePlayer();
    // _audioRecorder.dispose();
    _recordingTimer.stop();
    _waveformTimer?.cancel();
    super.dispose();
  }

  Future<void> _initAudioPlayer() async {
    await _audioPlayer.openPlayer();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        widget.note.images.add(pickedFile.path);
      });
    }
  }

  // 开始波形动画
  void _startWaveformAnimation() {
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        _waveformIndex = (_waveformIndex + 1) % _waveformValues.length;
      });
    });
  }

  // 停止波形动画
  void _stopWaveformAnimation() {
    _waveformTimer?.cancel();
    _waveformTimer = null;
  }

  // 更新为 record 6.0.0 兼容的录音实现
  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone
          .request()
          .isGranted) {
        final directory = await getApplicationDocumentsDirectory();
        _currentRecordingPath =
        '${directory.path}/audio_${DateTime
            .now()
            .millisecondsSinceEpoch}.m4a';

        // 配置录音参数 - 兼容 record 6.0.0
        // await _audioRecorder.start(
        //   path: _currentRecordingPath!,
        //   encoder: AudioEncoder.aacLc, // AAC编码
        //   bitRate: 128000, // 比特率
        //   samplingRate: 44100, // 采样率
        // );

        setState(() {
          _isRecording = true;
        });

        // 开始计时和波形动画
        _recordingTimer.start();
        _startWaveformAnimation();
      }
    } catch (e) {
      print('Error recording audio: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      // final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        // widget.note.audioPath = path;
      });

      // 停止计时和波形动画
      _recordingTimer.stop();
      _stopWaveformAnimation();
      setState(() {
        _recordingTime = '00:00';
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _playAudio() async {
    if (widget.note.audioPath != null) {
      if (_isPlaying) {
        await _audioPlayer.stopPlayer();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _audioPlayer.startPlayer(
          fromURI: widget.note.audioPath,
          whenFinished: () {
            setState(() {
              _isPlaying = false;
            });
          },
        );
        setState(() {
          _isPlaying = true;
        });
      }
    }
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      // 标题和内容不能都为空
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入标题或内容'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.note.title = title;
    widget.note.content = content;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    // 修复键盘弹出时的溢出问题
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          '编辑便签',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.save, size: 18),
            label: const Text('保存'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            onPressed: _saveNote,
          ),
        ],
      ),
      // 使用 resizeToAvoidBottomInset 解决键盘弹出时的溢出问题
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          // 添加额外的底部 padding，确保内容不被底部工具栏遮挡
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery
                  .of(context)
                  .viewInsets
                  .bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题输入框
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: '标题',
                        hintStyle: TextStyle(color: AppTheme.textHint),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 内容输入框
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        hintText: '内容',
                        hintStyle: TextStyle(color: AppTheme.textHint),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                        height: 1.5,
                      ),
                      maxLines: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 图片区域
                if (widget.note.images.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      '图片',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.note.images.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                // 图片容器 - 添加点击预览功能
                                GestureDetector(
                                  onTap: () {
                                    // 显示全屏预览
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                            ImagePreviewPage(
                                              images: widget.note.images,
                                              initialIndex: index,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(
                                          File(widget.note.images[index]),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                // 删除按钮 - 优化尺寸和位置
                                Positioned(
                                  right: 16,
                                  top: 4,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        setState(() {
                                          widget.note.images.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 录音区域
                if (_isRecording || widget.note.audioPath != null) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      '语音',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child:
                      _isRecording
                          ? _buildRecordingIndicator()
                          : Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPlaying
                                  ? Icons.stop
                                  : Icons.play_arrow,
                              color: AppTheme.primary,
                            ),
                            onPressed: _playAudio,
                          ),
                          const Text(
                            '语音备忘录',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                widget.note.audioPath = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                // 主题选择区域
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    '主题',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                        AppTheme.noteThemes.entries.map((entry) {
                          final isSelected = widget.note.theme == entry.key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  widget.note.theme = entry.key;
                                });
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: entry.value,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                    isSelected
                                        ? AppTheme.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child:
                                isSelected
                                    ? const Center(
                                  child: Icon(
                                    Icons.check,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                )
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomBarButton(
                icon: Icons.image,
                label: '图片',
                onPressed: _pickImage,
              ),
              _buildBottomBarButton(
                icon: _isRecording ? Icons.stop : Icons.mic,
                label: _isRecording ? '停止' : '录音',
                onPressed: _isRecording ? _stopRecording : _startRecording,
                isHighlighted: _isRecording,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 录音指示器
  Widget _buildRecordingIndicator() {
    return Row(
      children: [
        const Icon(Icons.mic, color: Colors.red),
        const SizedBox(width: 8),
        Text('录音中 $_recordingTime',
            style: const TextStyle(color: Colors.red)),
        const SizedBox(width: 16),
        // 波形动画
        Expanded(
          child: SizedBox(
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (index) {
                final waveIndex =
                    (index + _waveformIndex) % _waveformValues.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 3,
                  height: 20 * _waveformValues[waveIndex],
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  // 底部按钮
  Widget _buildBottomBarButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isHighlighted = false,
  }) {
    return SizedBox(
      height: 60, // 固定按钮总高度
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isHighlighted ? Colors.red : AppTheme.primary,
                size: 16,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isHighlighted ? Colors.red : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

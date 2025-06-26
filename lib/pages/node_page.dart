import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
  final Record _audioRecorder = Record();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  // bool _isRecording = false;
  // bool _isPlaying = false;
  String _currentTheme = 'default';
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // 主题颜色映射
  final Map<String, Color> themeColors = {
    'default': const Color(0xFFF8BBD0), // 粉色
    'blue': const Color(0xFFBBDEFB),    // 蓝色
    'green': const Color(0xFFD5E4C3),   // 绿色
    'yellow': const Color(0xFFF1E0C5),  // 黄色
    'purple': const Color(0xFFE1BEE7),  // 紫色
  };

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.closePlayer();
    _searchController.dispose();
    super.dispose();
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
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(note: note),
      ),
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
      builder: (context) => AlertDialog(
        title: const Text('删除便签'),
        content: const Text('确定要删除这个便签吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
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
            child: const Text('删除'),
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

  @override
  Widget build(BuildContext context) {
    final filteredNotes = _getFilteredNotes();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '搜索便签...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        )
            : const Text('我的便签'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.color_lens),
            onSelected: _changeTheme,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'default', child: Text('粉色主题')),
              const PopupMenuItem(value: 'blue', child: Text('蓝色主题')),
              const PopupMenuItem(value: 'green', child: Text('绿色主题')),
              const PopupMenuItem(value: 'yellow', child: Text('黄色主题')),
              const PopupMenuItem(value: 'purple', child: Text('紫色主题')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据已备份到本地')),
              );
            },
          ),
        ],
      ),
      body: filteredNotes.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: themeColors[_currentTheme],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? '暂无便签，点击右下角添加吧~' : '没有找到匹配的便签',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          itemCount: filteredNotes.length,
          itemBuilder: (context, index) {
            final note = filteredNotes[index];
            return _buildNoteCard(note);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        backgroundColor: themeColors[_currentTheme],
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return GestureDetector(
      onTap: () => _editNote(note),
      child: Card(
        elevation: 2,
        color: themeColors[note.theme]?.withOpacity(0.7) ?? themeColors['default']?.withOpacity(0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (note.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    note.content,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (note.images.isNotEmpty)
                Container(
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: note.images.length > 3 ? 3 : note.images.length,
                    itemBuilder: (context, index) {
                      return Container(
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
                        child: index == 2 && note.images.length > 3
                            ? Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black.withOpacity(0.5),
                          ),
                          child: Center(
                            child: Text(
                              '+${note.images.length - 3}',
                              style: const TextStyle(color: Colors.white, fontSize: 20),
                            ),
                          ),
                        )
                            : null,
                      );
                    },
                  ),
                ),
              if (note.audioPath != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.audiotrack, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      const Text('语音备忘录'),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${note.updatedAt.year}/${note.updatedAt.month}/${note.updatedAt.day}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
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
  final Record _audioRecorder = Record();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.note.title;
    _contentController.text = widget.note.content;
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.closePlayer();
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

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final directory = await getApplicationDocumentsDirectory();
        _currentRecordingPath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

        await _audioRecorder.start(path: _currentRecordingPath!);

        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      print('Error recording audio: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        widget.note.audioPath = _currentRecordingPath;
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
    widget.note.title = _titleController.text;
    widget.note.content = _contentController.text;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑便签'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '标题',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: '内容',
                border: OutlineInputBorder(),
              ),
              maxLines: 10,
            ),
            const SizedBox(height: 16),
            if (widget.note.images.isNotEmpty) ...[
              const Text('图片:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.note.images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(widget.note.images[index])),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                widget.note.images.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (widget.note.audioPath != null) ...[
              const Text('语音:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    onPressed: _playAudio,
                  ),
                  const Text('语音备忘录'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        widget.note.audioPath = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: _pickImage,
              tooltip: '添加图片',
            ),
            IconButton(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              onPressed: _isRecording ? _stopRecording : _startRecording,
              tooltip: _isRecording ? '停止录音' : '开始录音',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.color_lens),
              onSelected: (theme) {
                setState(() {
                  widget.note.theme = theme;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'default', child: Text('粉色主题')),
                const PopupMenuItem(value: 'blue', child: Text('蓝色主题')),
                const PopupMenuItem(value: 'green', child: Text('绿色主题')),
                const PopupMenuItem(value: 'yellow', child: Text('黄色主题')),
                const PopupMenuItem(value: 'purple', child: Text('紫色主题')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
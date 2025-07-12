import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/node_page.dart';

class FloatingNoteService extends StatefulWidget {
  const FloatingNoteService({Key? key}) : super(key: key);

  @override
  State<FloatingNoteService> createState() => _FloatingNoteServiceState();
}

class _FloatingNoteServiceState extends State<FloatingNoteService> {
  Note? note;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final prefs = await SharedPreferences.getInstance();
    final noteJson = prefs.getString('floating_note');
    if (noteJson != null) {
      final noteData = jsonDecode(noteJson);
      setState(() {
        note = Note(
          id: noteData['id'],
          title: noteData['title'],
          content: noteData['content'],
          images: List<String>.from(noteData['images']),
          audioPath: noteData['audioPath'],
          createdAt: DateTime.parse(noteData['createdAt']),
          updatedAt: DateTime.parse(noteData['updatedAt']),
          theme: noteData['theme'],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (note == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final themeColor = AppTheme.noteThemes[note!.theme] ?? AppTheme.noteThemes['default'];

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () async {
          // 点击关闭悬浮窗
          await FlutterOverlayWindow.closeOverlay();
        },
        child: Container(
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note!.title.isNotEmpty ? note!.title : '无标题便签',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await FlutterOverlayWindow.closeOverlay();
                    },
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    note!.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (note!.images.isNotEmpty)
                Container(
                  height: 60,
                  margin: const EdgeInsets.only(top: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: note!.images.length > 3 ? 3 : note!.images.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(note!.images[index])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
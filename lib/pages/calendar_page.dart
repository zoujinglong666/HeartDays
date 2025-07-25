import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heart_days/apis/anniversary.dart';
import 'package:heart_days/components/AnniversaryCalendar.dart';
import 'package:heart_days/pages/add_anniversary.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:heart_days/utils/SafeNavigator.dart';
import 'package:heart_days/common/event_bus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<Anniversary> _anniversaries = [];
  DateTime? _selectedDate;
  List<Anniversary> _selectedDateEvents = [];
  bool _isLoading = true;
  StreamSubscription? _anniversarySubscription;

  @override
  void initState() {
    super.initState();
    _loadAnniversaries();
    _anniversarySubscription = eventBus.on<AnniversaryListUpdated>().listen((
      event,
    ) {
      _loadAnniversaries();
    });
  }

  Future<void> _loadAnniversaries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final authDataString = prefs.getString('auth_data');
      if (authDataString != null) {
        final Map<String, dynamic> authMap = jsonDecode(authDataString);
        final authState = AuthState.fromJson(authMap);
        if (authState.user?.id != null) {
          final response = await fetchAnniversaryListByUserId(
            authState.user!.id,
          );
          setState(() {
            _anniversaries = response.data ?? [];
          });
        } else {
          _anniversaries = [];
        }
      }
    } catch (e) {
      print('加载纪念日失败: $e');
      _anniversaries = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _anniversarySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('纪念日日历'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnniversaries,
          ),
        ],
      ),
      body: Container(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 日历组件
                      Padding(
                        padding: const EdgeInsets.all(0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          // 用ClipRect包裹日历，防止极小溢出
                          child: ClipRect(
                            child: AnniversaryCalendar(
                              anniversaries: _anniversaries,
                              onDaySelected: (date) {
                                setState(() {
                                  _selectedDate = date;
                                  _selectedDateEvents = [];
                                });
                              },
                              onDayWithEventsSelected: (date, events) {
                                setState(() {
                                  _selectedDate = date;
                                  _selectedDateEvents = events;
                                });
                              },
                              primaryColor: const Color(0xFFF48FB1),
                              accentColor: const Color(0xFF64B5F6),
                            ),
                          ),
                        ),
                      ),

                      // 无纪念日时空视图
                      if (_anniversaries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                "你还没有添加任何纪念日",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 选中日期信息
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child:
                            _selectedDate != null
                                ? Padding(
                                  key: ValueKey(_selectedDate),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: _buildSelectedDateCard(),
                                )
                                : const SizedBox.shrink(),
                      ),

                      // 添加按钮
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            SafeNavigator.pushOnce(
                              context,
                              const AddAnniversaryPage(),
                            );
                          },
                          icon: const Icon(Icons.favorite_border),
                          label: const Text('添加纪念日'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF48FB1),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: Colors.pink.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildSelectedDateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, const Color(0xFFFFF0F5)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Color(0xFFF48FB1),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('yyyy年MM月dd日').format(_selectedDate!),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedDateEvents.isNotEmpty)
            ..._selectedDateEvents.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(event.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (event.description.isNotEmpty)
                            Text(
                              event.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            event.color?.withOpacity(0.2) ??
                            Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.type,
                        style: TextStyle(
                          color: event.color ?? Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              '这一天还没有纪念日',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }
}

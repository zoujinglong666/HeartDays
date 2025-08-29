import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/apis/anniversary.dart';
import 'package:heart_days/common/event_bus.dart';
import 'package:heart_days/components/AnniversaryCalendar.dart';
import 'package:heart_days/pages/add_anniversary.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:heart_days/utils/SafeNavigator.dart';
import 'package:intl/intl.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
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
      final authState = ref.read(authProvider);
      final user = authState.user;
      final response = await fetchAnniversaryListByUserId(user!.id);

      final today = DateTime.now();
      final todayWithoutTime = DateTime(today.year, today.month, today.day);

      final todayEvents = response.data
          ?.where((anniversary) {
        final date = anniversary.date;
        final anniversaryDate = DateTime(date.year, date.month, date.day);
        return anniversaryDate == todayWithoutTime;
      })
          .toList() ?? [];

      setState(() {
        _anniversaries = response.data ?? [];
        _selectedDate = todayWithoutTime;
        _selectedDateEvents = todayEvents;
      });
    } catch (e) {
      print('加载纪念日失败: $e');
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
      extendBodyBehindAppBar: true, // 让 body 延伸到 appBar 背后，实现沉浸式毛玻璃
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              elevation: 0,
              backgroundColor: Colors.white.withOpacity(0.7),
              centerTitle: true,
              title: const Text(
                '日历统计',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.black87),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 日历组件
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
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

                      // 无纪念日提示
                      if (_anniversaries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 48,
                          ),
                          child: Center(
                            child: Text(
                              "你还没有添加任何纪念日",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),

                      // 选中日期信息卡片
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _selectedDate != null
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

                      // 优化的添加纪念日按钮
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFF48FB1),
                                Color(0xFFE91E63),
                                Color(0xFFAD1457),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF48FB1).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              SafeNavigator.pushOnce(
                                context,
                                const AddAnniversaryPage(),
                              );
                            },
                            icon: const Icon(
                              Icons.favorite_rounded,
                              size: 22,
                            ),
                            label: const Text('添加纪念日'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),

    );
  }



  Widget _buildSelectedDateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFFFF0F5),
            Color(0xFFFCE4EC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF48FB1).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF48FB1).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF48FB1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFFF48FB1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('yyyy年MM月dd日').format(_selectedDate!),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedDateEvents.isNotEmpty)
            ..._selectedDateEvents.map(
              (event) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (event.color ?? const Color(0xFFF48FB1)).withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (event.color ?? const Color(0xFFF48FB1)).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        event.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          if (event.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              event.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (event.color ?? const Color(0xFFF48FB1)).withOpacity(0.8),
                            (event.color ?? const Color(0xFFF48FB1)),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: (event.color ?? const Color(0xFFF48FB1)).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        event.type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.event_available_rounded,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '这一天还没有纪念日',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

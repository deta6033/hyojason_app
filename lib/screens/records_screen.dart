import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'detail_screens.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  bool calendarMode = false;
  late DateTime selectedDate;
  late DateTime displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDate = now;
    displayedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('지난 기록', style: AppTheme.displayStyle),
            const SizedBox(height: 5),
            Text('어르신의 지난 하루를 날짜별로 확인해보세요.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted)),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.list_rounded), label: Text('리스트')),
                ButtonSegment(value: true, icon: Icon(Icons.calendar_month_rounded), label: Text('달력')),
              ],
              selected: {calendarMode},
              onSelectionChanged: (value) => setState(() => calendarMode = value.first),
            ),
            const SizedBox(height: 18),
            Expanded(child: calendarMode ? _calendar(state) : _list(state)),
          ],
        ),
      ),
    );
  }

  Widget _list(AppState state) {
    final records = [...state.records]..sort((a, b) => b.date.compareTo(a.date));
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final record = records[index];
        final needsAttention = !record.medicine;
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DailySummaryScreen(record: record)),
          ),
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppTheme.border)),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: needsAttention ? AppTheme.orangeSoft : AppTheme.blueSoft,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    needsAttention ? Icons.warning_amber_rounded : Icons.calendar_today_rounded,
                    color: needsAttention ? AppTheme.warning : AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatKoreanDate(record.date), style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(
                        '기분 ${record.mood} · 복약 ${record.medicine ? '완료' : '미확인'} · 외출 ${record.outing ? '있음' : '없음'}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _calendar(AppState state) {
    final selectedRecord = state.recordForDate(selectedDate);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border), boxShadow: AppTheme.softShadow),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => setState(() {
                        displayedMonth = DateTime(displayedMonth.year, displayedMonth.month - 1);
                      }),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Text(
                      '${displayedMonth.year}년 ${displayedMonth.month}월',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        displayedMonth = DateTime(displayedMonth.year, displayedMonth.month + 1);
                      }),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _MonthCalendar(
                  month: displayedMonth,
                  selectedDate: selectedDate,
                  records: state.records,
                  onDateSelected: (date) => setState(() => selectedDate = date),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (selectedRecord == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text(
                '${formatKoreanDate(selectedDate)}에는 저장된 기록이 없어요.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.muted),
              ),
            )
          else
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DailySummaryScreen(record: selectedRecord)),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppTheme.greenSoft, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFDCEFE3))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatKoreanDate(selectedRecord.date), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 9),
                    Text(selectedRecord.summary, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.5)),
                    const SizedBox(height: 8),
                    const Text('눌러서 자세히 보기', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;
  final List<DailyRecord> records;
  final ValueChanged<DateTime> onDateSelected;

  const _MonthCalendar({
    required this.month,
    required this.selectedDate,
    required this.records,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;
    final cellCount = leadingEmpty + daysInMonth;
    const weekNames = ['월', '화', '수', '목', '금', '토', '일'];

    return Column(
      children: [
        Row(
          children: weekNames
              .map((day) => Expanded(
                    child: Center(child: Text(day, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemCount: cellCount,
          itemBuilder: (context, index) {
            if (index < leadingEmpty) return const SizedBox();
            final day = index - leadingEmpty + 1;
            final date = DateTime(month.year, month.month, day);
            final selected = isSameDate(date, selectedDate);
            final hasRecord = records.any((record) => isSameDate(record.date, date));
            final warning = records.any((record) => isSameDate(record.date, date) && !record.medicine);
            return InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: () => onDateSelected(date),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(color: selected ? Colors.white : AppTheme.text, fontWeight: selected ? FontWeight.w800 : FontWeight.normal),
                    ),
                    const SizedBox(height: 2),
                    if (hasRecord)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : (warning ? AppTheme.warning : AppTheme.success),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

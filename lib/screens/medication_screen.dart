import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('복약 일정', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                      SizedBox(height: 5),
                      Text('보호자가 등록한 시간에 실제 휴대폰 알림을 받을 수 있어요.', style: TextStyle(color: AppTheme.muted)),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openEditor(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('추가'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Expanded(
              child: state.medications.isEmpty
                  ? const _EmptyMedication()
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: state.medications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final schedule = state.medications[index];
                        return _MedicationCard(
                          schedule: schedule,
                          onEdit: () => _openEditor(context, existing: schedule),
                          onDelete: () => _deleteSchedule(context, schedule),
                          onToggle: (value) => state.updateMedication(schedule.copyWith(enabled: value)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {MedicationSchedule? existing}) async {
    final state = AppScope.of(context);
    final result = await showModalBottomSheet<MedicationSchedule>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MedicationEditor(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await state.addMedication(result);
    } else {
      await state.updateMedication(result);
    }
  }

  Future<void> _deleteSchedule(BuildContext context, MedicationSchedule schedule) async {
    final state = AppScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('복약 일정 삭제'),
        content: Text('${schedule.name} 일정을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed == true) await state.deleteMedication(schedule.id);
  }
}

class _MedicationCard extends StatelessWidget {
  final MedicationSchedule schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _MedicationCard({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: schedule.enabled ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: AppTheme.purpleSoft, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.medication_rounded, color: Color(0xFF745FD4)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(schedule.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${schedule.timeText} · ${schedule.daysText}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Switch(value: schedule.enabled, onChanged: onToggle),
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('수정')),
                PopupMenuItem(value: 'delete', child: Text('삭제')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationEditor extends StatefulWidget {
  final MedicationSchedule? existing;

  const _MedicationEditor({this.existing});

  @override
  State<_MedicationEditor> createState() => _MedicationEditorState();
}

class _MedicationEditorState extends State<_MedicationEditor> {
  late final TextEditingController nameController;
  late int hour;
  late int minute;
  late Set<int> selectedDays;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.existing?.name ?? '');
    hour = widget.existing?.hour ?? 17;
    minute = widget.existing?.minute ?? 0;
    selectedDays = Set<int>.from(widget.existing?.days ?? const [1, 2, 3, 4, 5, 6, 7]);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
  if (result != null) {
  setState(() {
    hour = result.hour;
    minute = result.minute;
  });
}
  }

  @override
  Widget build(BuildContext context) {
    const dayNames = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
    final timeText = MedicationSchedule(
      id: '',
      name: '',
      hour: hour,
      minute: minute,
      days: const [],
      enabled: true,
    ).timeText;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFD5D9DE), borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.existing == null ? '복약 일정 추가' : '복약 일정 수정',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '약 이름', hintText: '예: 혈압약'),
              ),
              const SizedBox(height: 18),
              const Text('복약 시간', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ListTile(
                tileColor: const Color(0xFFF4F6F9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const Icon(Icons.schedule_rounded),
                title: Text(timeText, style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _selectTime,
              ),
              const SizedBox(height: 20),
              const Text('반복 요일', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: dayNames.entries.map((entry) {
                  final selected = selectedDays.contains(entry.key);
                  return FilterChip(
                    label: Text(entry.value),
                    selected: selected,
                    onSelected: (value) => setState(() {
                      value ? selectedDays.add(entry.key) : selectedDays.remove(entry.key);
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty || selectedDays.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('약 이름과 반복 요일을 선택해주세요.')),
                      );
                      return;
                    }
                    Navigator.pop(
                      context,
                      MedicationSchedule(
                        id: widget.existing?.id ?? 'medicine_${DateTime.now().microsecondsSinceEpoch}',
                        name: name,
                        hour: hour,
                        minute: minute,
                        days: selectedDays.toList()..sort(),
                        enabled: widget.existing?.enabled ?? true,
                      ),
                    );
                  },
                  child: Text(widget.existing == null ? '일정 추가' : '수정 완료'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMedication extends StatelessWidget {
  const _EmptyMedication();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medication_outlined, size: 54, color: Color(0xFFB5BCC5)),
          SizedBox(height: 12),
          Text('등록된 복약 일정이 없어요.', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('오른쪽 위 + 추가 버튼으로 등록해보세요.', style: TextStyle(color: AppTheme.muted)),
        ],
      ),
    );
  }
}

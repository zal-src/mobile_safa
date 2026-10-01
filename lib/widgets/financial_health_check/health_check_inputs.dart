import 'package:flutter/material.dart';

class HealthCheckNumberInput extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const HealthCheckNumberInput({
    super.key,
    required this.title,
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F7F1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF087443), size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF101828),
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
            suffixText: 'บาท',
            suffixStyle: const TextStyle(fontSize: 18, color: Color(0xFF667085)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF087443), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class HealthCheckRadioSelection extends StatelessWidget {
  final bool hasUpcomingDebt;
  final ValueChanged<bool> onChanged;

  const HealthCheckRadioSelection({
    super.key,
    required this.hasUpcomingDebt,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFFEE4E2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.event_busy_outlined, color: Color(0xFFD92D20), size: 32),
        ),
        const SizedBox(height: 24),
        const Text(
          'คุณมีหนี้ที่กำลังจะครบกำหนดหรือไม่?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF101828),
          ),
        ),
        const SizedBox(height: 32),
        _buildRadioOption('ไม่มี', false),
        const SizedBox(height: 16),
        _buildRadioOption('มี', true),
      ],
    );
  }

  Widget _buildRadioOption(String title, bool value) {
    final isSelected = hasUpcomingDebt == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F7F1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF087443) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF087443) : Colors.grey.shade400,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF101828),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

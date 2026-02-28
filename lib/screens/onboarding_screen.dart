import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  final StorageService storageService;

  const OnboardingScreen({super.key, required this.storageService});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  // Form values
  String? _sex;
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  double _screenTimeHours = 4.0;
  bool _heightInCm = false;
  bool _weightInKg = false;

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    switch (_currentPage) {
      case 0:
        return _sex != null;
      case 1:
        final age = int.tryParse(_ageController.text);
        return age != null && age > 0 && age < 120;
      case 2:
        final h = double.tryParse(_heightController.text);
        return h != null && h > 0;
      case 3:
        final w = double.tryParse(_weightController.text);
        return w != null && w > 0;
      case 4:
        return true;
      default:
        return false;
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  double get _heightInCmValue {
    final val = double.tryParse(_heightController.text) ?? 0;
    if (_heightInCm) return val;
    // convert inches to cm
    return val * 2.54;
  }

  double get _weightInKgValue {
    final val = double.tryParse(_weightController.text) ?? 0;
    if (_weightInKg) return val;
    // convert lbs to kg
    return val * 0.453592;
  }

  Future<void> _submit() async {
    final profile = UserProfile(
      sex: _sex!,
      age: int.parse(_ageController.text),
      heightCm: _heightInCmValue,
      weightKg: _weightInKgValue,
      dailyScreenTimeHours: _screenTimeHours,
    );
    await widget.storageService.saveUserProfile(profile);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildSexPage(),
                  _buildAgePage(),
                  _buildHeightPage(),
                  _buildWeightPage(),
                  _buildScreenTimePage(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bedtime_rounded,
                    color: AppColors.accentTeal, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Somnix',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${_currentPage + 1} of $_totalPages',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
            Text(
              '${((_currentPage + 1) / _totalPages * 100).round()}%',
              style: const TextStyle(
                  color: AppColors.accentTeal, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: AppColors.cardBorder,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: Row(
        children: [
          if (_currentPage > 0)
            OutlinedButton(
              onPressed: _prevPage,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.cardBorder),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back'),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _canAdvance ? _nextPage : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                foregroundColor: AppColors.background,
                disabledBackgroundColor: AppColors.cardBorder,
                disabledForegroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _currentPage == _totalPages - 1 ? 'Get Started' : 'Continue',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pages ────────────────────────────────────────────────────────────────

  Widget _buildSexPage() {
    final options = ['Male', 'Female', 'Other', 'Prefer not to say'];
    return _PageWrapper(
      title: 'What is your biological sex?',
      subtitle:
          'This helps us tailor your sleep analysis and health insights.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: options
            .map((opt) => _SelectionChip(
                  label: opt,
                  selected: _sex == opt,
                  onTap: () => setState(() => _sex = opt),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildAgePage() {
    return _PageWrapper(
      title: 'How old are you?',
      subtitle: 'Age affects sleep patterns and recommended sleep duration.',
      child: _NumberField(
        controller: _ageController,
        label: 'Age',
        unit: 'years',
        hint: 'e.g. 28',
        min: 1,
        max: 119,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildHeightPage() {
    return _PageWrapper(
      title: 'What is your height?',
      subtitle: 'Used to calculate your BMI and sleep health metrics.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UnitToggle(
            options: const ['cm', 'in'],
            selected: _heightInCm ? 0 : 1,
            onChanged: (i) => setState(() {
              _heightController.clear();
              _heightInCm = i == 0;
            }),
          ),
          const SizedBox(height: 16),
          _NumberField(
            controller: _heightController,
            label: 'Height',
            unit: _heightInCm ? 'cm' : 'in',
            hint: _heightInCm ? 'e.g. 175' : 'e.g. 69',
            min: 1,
            max: _heightInCm ? 300 : 120,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightPage() {
    return _PageWrapper(
      title: 'What is your weight?',
      subtitle: 'Weight can impact sleep apnea risk and sleep quality.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UnitToggle(
            options: const ['kg', 'lbs'],
            selected: _weightInKg ? 0 : 1,
            onChanged: (i) => setState(() {
              _weightController.clear();
              _weightInKg = i == 0;
            }),
          ),
          const SizedBox(height: 16),
          _NumberField(
            controller: _weightController,
            label: 'Weight',
            unit: _weightInKg ? 'kg' : 'lbs',
            hint: _weightInKg ? 'e.g. 70' : 'e.g. 154',
            min: 1,
            max: _weightInKg ? 500 : 1100,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenTimePage() {
    final hours = _screenTimeHours.round();
    final label = hours >= 12 ? '12+ hours' : '$hours ${hours == 1 ? 'hour' : 'hours'}';

    return _PageWrapper(
      title: 'Daily screen time',
      subtitle:
          'How many hours a day do you typically spend on screens (phone, TV, computer)?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.accentTeal,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.accentTeal,
                    inactiveTrackColor: AppColors.cardBorder,
                    thumbColor: AppColors.accentTeal,
                    overlayColor: AppColors.accentTeal.withOpacity(0.15),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _screenTimeHours,
                    min: 0,
                    max: 12,
                    divisions: 24,
                    onChanged: (v) => setState(() => _screenTimeHours = v),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('0 hrs',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    Text('12+ hrs',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _screenTimeNote(_screenTimeHours),
        ],
      ),
    );
  }

  Widget _screenTimeNote(double hours) {
    String text;
    Color color;
    if (hours <= 2) {
      text = 'Great — low screen time supports healthy sleep.';
      color = AppColors.scoreGreen;
    } else if (hours <= 5) {
      text = 'Moderate screen time. Consider limiting screens before bed.';
      color = AppColors.scoreYellow;
    } else {
      text = 'High screen time may disrupt your sleep cycle.';
      color = AppColors.accentRed;
    }
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text,
              style: TextStyle(color: color, fontSize: 12)),
        ),
      ],
    );
  }
}

// ── Shared helper widgets ──────────────────────────────────────────────────

class _PageWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _PageWrapper({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentTeal.withOpacity(0.15)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accentTeal : AppColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accentTeal : AppColors.textSecondary,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  const _UnitToggle({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.asMap().entries.map((e) {
          final isSelected = e.key == selected;
          return GestureDetector(
            onTap: () => onChanged(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentTeal.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.accentTeal
                      : AppColors.textMuted,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final String hint;
  final double min;
  final double max;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.hint,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
      ],
      onChanged: onChanged,
      style: const TextStyle(
          color: AppColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.textSecondary),
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textMuted),
        suffixText: unit,
        suffixStyle: const TextStyle(
            color: AppColors.accentTeal, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: AppColors.accentTeal, width: 1.5),
        ),
      ),
    );
  }
}

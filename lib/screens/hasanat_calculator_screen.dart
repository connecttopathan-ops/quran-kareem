import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../theme/app_theme.dart';
import '../widgets/q_icons.dart';
import '../data/hasanat_promises.dart';

class HasanatCalculatorScreen extends StatefulWidget {
  const HasanatCalculatorScreen({super.key});

  @override
  State<HasanatCalculatorScreen> createState() =>
      _HasanatCalculatorScreenState();
}

class _HasanatCalculatorScreenState extends State<HasanatCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late String _currencyCode;
  late String _currencySymbol;
  late NumberFormat _numberFormat;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initCurrencyFromLocale();
  }

  void _initCurrencyFromLocale() {
    String locale;
    try {
      locale = Platform.localeName;
    } catch (_) {
      locale = 'en_US';
    }
    final fmt = NumberFormat.simpleCurrency(locale: locale);
    _currencyCode = fmt.currencyName ?? 'USD';
    _currencySymbol = fmt.currencySymbol;
    _numberFormat = NumberFormat.decimalPattern(locale);
  }

  void _setCurrency(String code) {
    final fmt = NumberFormat.simpleCurrency(name: code);
    setState(() {
      _currencyCode = code;
      _currencySymbol = fmt.currencySymbol;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(
          icon: QIcon.back(size: 22, color: context.textDim),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hasanat Calculator',
              style: TextStyle(
                color: context.text,
                fontSize: 16,
                fontFamily: 'serif',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Rewards promised in the Quran & Hadeeth',
              style: TextStyle(
                color: context.textDim,
                fontSize: 10,
                fontStyle: FontStyle.italic,
                fontFamily: 'sans-serif',
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 1, color: context.border),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.gold,
                unselectedLabelColor: context.textDim,
                indicatorColor: AppColors.gold,
                indicatorWeight: 2,
                labelStyle: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'sans-serif',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'sans-serif',
                    fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'One Time'),
                  Tab(text: 'Recurring'),
                ],
              ),
              Container(height: 1, color: context.border),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OneTimeTab(
            currencyCode: _currencyCode,
            currencySymbol: _currencySymbol,
            numberFormat: _numberFormat,
            onCurrencyChanged: _setCurrency,
          ),
          _RecurringTab(
            currencyCode: _currencyCode,
            currencySymbol: _currencySymbol,
            numberFormat: _numberFormat,
            onCurrencyChanged: _setCurrency,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// ONE TIME TAB
// ─────────────────────────────────────────────────
class _OneTimeTab extends StatefulWidget {
  final String currencyCode;
  final String currencySymbol;
  final NumberFormat numberFormat;
  final ValueChanged<String> onCurrencyChanged;
  const _OneTimeTab({
    required this.currencyCode,
    required this.currencySymbol,
    required this.numberFormat,
    required this.onCurrencyChanged,
  });

  @override
  State<_OneTimeTab> createState() => _OneTimeTabState();
}

class _OneTimeTabState extends State<_OneTimeTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _amountCtrl = TextEditingController(text: '100');
  String _selectedCategoryKey = 'general';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  DeedCategory get _category => sadaqahCategories
      .firstWhere((c) => c.key == _selectedCategoryKey,
          orElse: () => sadaqahCategories.first);

  double get _amount =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '').trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cat = _category;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _NiyyahBanner(),
        const SizedBox(height: AppSpacing.md),
        _SectionLabel('Amount'),
        const SizedBox(height: AppSpacing.sm),
        _AmountRow(
          controller: _amountCtrl,
          currencyCode: widget.currencyCode,
          currencySymbol: widget.currencySymbol,
          onCurrencyChanged: widget.onCurrencyChanged,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionLabel('Type of Deed'),
        const SizedBox(height: AppSpacing.sm),
        _ChipsRow(
          options: sadaqahCategories
              .map((c) => (key: c.key, label: c.label))
              .toList(),
          selectedKey: _selectedCategoryKey,
          onTap: (k) => setState(() => _selectedCategoryKey = k),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...cat.promises.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _PromiseCard(promise: p),
            )),
        if (cat.minMultiplier != null && _amount > 0) ...[
          _FootnoteNumber(
            label: 'Minimum (per ${cat.minSource})',
            value:
                widget.numberFormat.format(_amount.round() * cat.minMultiplier!),
            unit: 'hasanat',
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (cat.maxMultiplier != null && _amount > 0) ...[
          _FootnoteNumber(
            label: 'Up to (per ${cat.maxSource})',
            value:
                widget.numberFormat.format(_amount.round() * cat.maxMultiplier!),
            unit: 'hasanat',
          ),
          const SizedBox(height: AppSpacing.lg),
        ] else
          const SizedBox(height: AppSpacing.md),
        _ConditionsCard(conditions: cat.conditions),
        const SizedBox(height: AppSpacing.md),
        const _Disclaimer(
            text:
                'The figures above are read directly from the cited verses — they are Allah\'s promise, not our calculation. Only Allah knows true acceptance.'),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// RECURRING TAB
// ─────────────────────────────────────────────────
class _RecurringTab extends StatefulWidget {
  final String currencyCode;
  final String currencySymbol;
  final NumberFormat numberFormat;
  final ValueChanged<String> onCurrencyChanged;
  const _RecurringTab({
    required this.currencyCode,
    required this.currencySymbol,
    required this.numberFormat,
    required this.onCurrencyChanged,
  });

  @override
  State<_RecurringTab> createState() => _RecurringTabState();
}

class _RecurringTabState extends State<_RecurringTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _amountCtrl = TextEditingController(text: '50');
  double _months = 60; // 5 years default
  String _selectedCategoryKey = 'jariyah';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  DeedCategory get _category => sadaqahCategories
      .firstWhere((c) => c.key == _selectedCategoryKey,
          orElse: () => sadaqahCategories.first);

  double get _monthlyAmount =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
  double get _totalAmount => _monthlyAmount * _months;

  String _formatDuration(double m) {
    final months = m.round();
    if (months < 12) return '$months month${months == 1 ? '' : 's'}';
    final years = months ~/ 12;
    final rem = months % 12;
    if (rem == 0) return '$years year${years == 1 ? '' : 's'}';
    return '$years yr ${rem}m';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cat = _category;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _NiyyahBanner(),
        const SizedBox(height: AppSpacing.md),
        _SectionLabel('Monthly Amount'),
        const SizedBox(height: AppSpacing.sm),
        _AmountRow(
          controller: _amountCtrl,
          currencyCode: widget.currencyCode,
          currencySymbol: widget.currencySymbol,
          onCurrencyChanged: widget.onCurrencyChanged,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionLabel('Duration'),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _formatDuration(_months),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.gold,
            fontFamily: 'serif',
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.gold,
            inactiveTrackColor: context.border,
            thumbColor: AppColors.gold,
            overlayColor: AppColors.gold.withOpacity(0.15),
            trackHeight: 3,
          ),
          child: Slider(
            value: _months,
            min: 1,
            max: 360,
            divisions: 359,
            onChanged: (v) => setState(() => _months = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 month',
                  style: TextStyle(
                      fontSize: 11,
                      color: context.textDim,
                      fontFamily: 'sans-serif')),
              Text('30 years',
                  style: TextStyle(
                      fontSize: 11,
                      color: context.textDim,
                      fontFamily: 'sans-serif')),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionLabel('Type of Deed'),
        const SizedBox(height: AppSpacing.sm),
        _ChipsRow(
          options: sadaqahCategories
              .map((c) => (key: c.key, label: c.label))
              .toList(),
          selectedKey: _selectedCategoryKey,
          onTap: (k) => setState(() => _selectedCategoryKey = k),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...cat.promises.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _PromiseCard(promise: p),
            )),
        _SummaryCard(
          rows: [
            (
              label: 'Monthly contribution',
              value:
                  '${widget.currencySymbol}${widget.numberFormat.format(_monthlyAmount.round())}'
            ),
            (
              label: 'Duration',
              value: _formatDuration(_months),
            ),
            (
              label: 'Total given',
              value:
                  '${widget.currencySymbol}${widget.numberFormat.format(_totalAmount.round())}'
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (cat.minMultiplier != null && _totalAmount > 0) ...[
          _FootnoteNumber(
            label: 'Minimum (per ${cat.minSource})',
            value: widget.numberFormat
                .format(_totalAmount.round() * cat.minMultiplier!),
            unit: 'hasanat',
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (cat.maxMultiplier != null && _totalAmount > 0) ...[
          _FootnoteNumber(
            label: 'Up to (per ${cat.maxSource})',
            value: widget.numberFormat
                .format(_totalAmount.round() * cat.maxMultiplier!),
            unit: 'hasanat',
          ),
          const SizedBox(height: AppSpacing.lg),
        ] else
          const SizedBox(height: AppSpacing.md),
        _ConditionsCard(conditions: cat.conditions),
        const SizedBox(height: AppSpacing.md),
        const _Disclaimer(
            text:
                'The figures above are read directly from the cited verses — they are Allah\'s promise, not our calculation. Only Allah knows true acceptance.'),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: context.isDark ? AppColors.goldDim : AppColors.goldDark,
        fontFamily: 'sans-serif',
      ),
    );
  }
}

class _NiyyahBanner extends StatelessWidget {
  const _NiyyahBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.gold.withOpacity(0.06)
            : AppColors.goldFaint.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color:
                context.isDark ? AppColors.darkGoldBorder : AppColors.goldBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.brightness_2_rounded,
              size: 16,
              color: context.isDark ? AppColors.gold : AppColors.goldDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: context.isDark ? AppColors.warmWhite : AppColors.deepText,
                  fontFamily: 'sans-serif',
                ),
                children: [
                  TextSpan(
                      text: 'Renew your niyyah. ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.isDark
                            ? AppColors.gold
                            : AppColors.goldDark,
                      )),
                  const TextSpan(
                      text:
                          'All deeds are by intention. Only Allah knows what He accepts.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final TextEditingController controller;
  final String currencyCode;
  final String currencySymbol;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onChanged;

  const _AmountRow({
    required this.controller,
    required this.currencyCode,
    required this.currencySymbol,
    required this.onCurrencyChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: context.border),
            ),
            child: Row(
              children: [
                Text(currencySymbol,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                        fontFamily: 'sans-serif')),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                    ],
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: context.text,
                        fontFamily: 'serif'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => _pickCurrency(context, currencyCode, onCurrencyChanged),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(currencyCode,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'sans-serif')),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _pickCurrency(BuildContext context, String current,
      ValueChanged<String> onChanged) {
    const codes = [
      'USD',
      'GBP',
      'EUR',
      'SAR',
      'AED',
      'PKR',
      'INR',
      'MYR',
      'CAD',
      'AUD',
      'TRY',
      'IDR',
      'BDT',
      'EGP'
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('Select Currency',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ctx.text,
                      fontFamily: 'serif')),
            ),
            ...codes.map((c) {
              final fmt = NumberFormat.simpleCurrency(name: c);
              final selected = c == current;
              return ListTile(
                dense: true,
                leading: Text(fmt.currencySymbol,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                        fontFamily: 'sans-serif')),
                title: Text(c,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ctx.text,
                        fontFamily: 'sans-serif')),
                trailing: selected
                    ? QIcon.check(size: 18, color: AppColors.gold)
                    : null,
                onTap: () {
                  onChanged(c);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ChipsRow extends StatelessWidget {
  final List<({String key, String label})> options;
  final String selectedKey;
  final ValueChanged<String> onTap;
  const _ChipsRow({
    required this.options,
    required this.selectedKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((o) {
        final selected = o.key == selectedKey;
        return GestureDetector(
          onTap: () => onTap(o.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.gold : context.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? AppColors.gold : context.border),
            ),
            child: Text(
              o.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : context.text,
                fontFamily: 'sans-serif',
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PromiseCard extends StatelessWidget {
  final HasanatPromise promise;
  const _PromiseCard({required this.promise});

  @override
  Widget build(BuildContext context) {
    final isQuran = promise.sourceType == 'quran';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: context.isDark
                ? AppColors.darkGoldBorder
                : AppColors.goldBorder,
            width: 1.4),
        boxShadow: AppShadows.card(context.isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded,
                  size: 18,
                  color: context.isDark
                      ? AppColors.gold
                      : AppColors.goldDark),
              const SizedBox(width: 6),
              Text(
                isQuran ? 'Allah\'s Promise' : 'Prophet ﷺ said',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: context.isDark
                      ? AppColors.gold
                      : AppColors.goldDark,
                  fontFamily: 'sans-serif',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isQuran ? 'QURAN' : 'HADEETH',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: context.isDark
                        ? AppColors.gold
                        : AppColors.goldDark,
                    fontFamily: 'sans-serif',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (promise.arabic != null) ...[
            Text(
              promise.arabic!,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.arabic(context.arabic, fontSize: 22)
                  .copyWith(height: 2.0),
            ),
            const SizedBox(height: 12),
          ],
          _HighlightedText(
            text: promise.translation,
            highlight: promise.highlight,
          ),
          const SizedBox(height: 10),
          Container(
            height: 1,
            color: AppColors.gold.withOpacity(0.2),
          ),
          const SizedBox(height: 10),
          Text(
            '— ${promise.source}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: context.isDark ? AppColors.gold : AppColors.goldDark,
              fontFamily: 'sans-serif',
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String? highlight;
  const _HighlightedText({required this.text, this.highlight});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: 14,
      height: 1.65,
      color: context.text,
      fontFamily: 'serif',
    );
    if (highlight == null || highlight!.isEmpty) {
      return Text(text, style: base);
    }
    final i = text.toLowerCase().indexOf(highlight!.toLowerCase());
    if (i < 0) return Text(text, style: base);
    final before = text.substring(0, i);
    final match = text.substring(i, i + highlight!.length);
    final after = text.substring(i + highlight!.length);
    return RichText(
      text: TextSpan(style: base, children: [
        TextSpan(text: before),
        TextSpan(
            text: match,
            style: base.copyWith(
              fontWeight: FontWeight.w700,
              color: context.isDark ? AppColors.gold : AppColors.goldDark,
            )),
        TextSpan(text: after),
      ]),
    );
  }
}

class _FootnoteNumber extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _FootnoteNumber({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(context.isDark ? 0.10 : 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.4),
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: context.textDim,
                fontFamily: 'sans-serif',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.gold,
              fontFamily: 'serif',
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            unit,
            style: TextStyle(
              fontSize: 11,
              color: context.textDim,
              fontFamily: 'sans-serif',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<({String label, String value})> rows;
  const _SummaryCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.border),
        boxShadow: AppShadows.card(context.isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.gold,
            child: Row(
              children: [
                const Icon(Icons.summarize_rounded,
                    size: 16, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Your Giving Plan',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.4,
                        fontFamily: 'sans-serif')),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Text(rows[i].label,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: context.textDim,
                            fontFamily: 'sans-serif')),
                  ),
                  Text(rows[i].value,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.text,
                          fontFamily: 'serif')),
                ],
              ),
            ),
            if (i < rows.length - 1)
              Container(
                  height: 1,
                  color: context.border.withOpacity(0.4),
                  margin: const EdgeInsets.symmetric(horizontal: 12)),
          ],
        ],
      ),
    );
  }
}

class _ConditionsCard extends StatelessWidget {
  final List<String> conditions;
  const _ConditionsCard({required this.conditions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.gold.withOpacity(0.04)
            : AppColors.goldFaint.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color:
                context.isDark ? AppColors.darkGoldBorder : AppColors.goldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded,
                  size: 16,
                  color: context.isDark
                      ? AppColors.gold
                      : AppColors.goldDark),
              const SizedBox(width: 6),
              Text('Conditions for Reward',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: context.isDark
                        ? AppColors.gold
                        : AppColors.goldDark,
                    fontFamily: 'sans-serif',
                  )),
            ],
          ),
          const SizedBox(height: 10),
          for (final c in conditions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(Icons.check_rounded,
                        size: 14,
                        color: context.isDark
                            ? AppColors.gold
                            : AppColors.goldDark),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(c,
                        style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: context.text,
                            fontFamily: 'sans-serif')),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  final String text;
  const _Disclaimer({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 14, color: context.textDim),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: context.textDim,
                    fontFamily: 'sans-serif')),
          ),
        ],
      ),
    );
  }
}

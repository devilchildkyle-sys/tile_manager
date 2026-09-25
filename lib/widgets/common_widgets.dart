import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../models/models.dart';

// ─── App Card ─────────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: padding ?? const EdgeInsets.all(14),
      child: child,
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text.toUpperCase(),
            style: const TextStyle(color: AppColors.muted, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

// ─── Field Label ──────────────────────────────────────────────────────────────
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text.toUpperCase(),
        style: const TextStyle(color: AppColors.muted, fontSize: 10,
            fontWeight: FontWeight.w600, letterSpacing: 0.5)),
  );
}

// ─── App Input ────────────────────────────────────────────────────────────────
class AppInput extends StatefulWidget {
  final String? label, hint, suffix;
  final String? value;
  final TextEditingController? controller; // pre-owned controller takes precedence
  final bool isNumber;
  final ValueChanged<String>? onChanged;
  final int? maxLines;

  const AppInput({super.key, this.label, this.hint, this.suffix,
      this.value, this.controller, this.isNumber = false,
      this.onChanged, this.maxLines = 1});

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  TextEditingController? _owned; // only set when we manage it ourselves

  TextEditingController get _ctrl => widget.controller ?? _owned!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _owned = TextEditingController(text: widget.value ?? '');
    }
  }

  @override
  void didUpdateWidget(AppInput old) {
    super.didUpdateWidget(old);
    if (widget.controller == null) {
      final incoming = widget.value ?? '';
      if (incoming != _ctrl.text) {
        final sel = _ctrl.selection;
        _ctrl.text = incoming;
        if (sel.isValid && sel.end <= incoming.length) _ctrl.selection = sel;
      }
    }
  }

  @override
  void dispose() { _owned?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.label != null) FieldLabel(widget.label!),
      TextField(
        controller: _ctrl,
        onChanged: widget.onChanged,
        maxLines: widget.maxLines,
        keyboardType: widget.isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: widget.isNumber
            ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
            : null,
        style: const TextStyle(color: AppColors.text, fontSize: 15),
        decoration: InputDecoration(
          hintText: widget.hint,
          suffixText: widget.suffix,
          suffixStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ),
    ],
  );
}

// ─── Stat Tile ────────────────────────────────────────────────────────────────
class StatTile extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const StatTile({super.key, required this.label, required this.value,
      required this.unit, this.color = AppColors.accent});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
          style: const TextStyle(color: AppColors.muted, fontSize: 10, letterSpacing: 0.5)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
      Text(unit, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
    ]),
  );
}

// ─── Tag ──────────────────────────────────────────────────────────────────────
class Tag extends StatelessWidget {
  final String label;
  final Color color;
  const Tag(this.label, {super.key, this.color = AppColors.accent});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

// ─── Difficulty Picker ────────────────────────────────────────────────────────
class DifficultyPicker extends StatelessWidget {
  final String label;
  final Difficulty? value;
  final List<LaborRate> rates;
  final String rateId;
  final ValueChanged<Difficulty?> onChanged;

  const DifficultyPicker({super.key, required this.label, required this.value,
      required this.rates, required this.rateId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final rate = rates.where((r) => r.id == rateId).firstOrNull;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FieldLabel(label),
      Row(children: Difficulty.values.map((d) {
        final sel = value == d;
        final r = rate?.rateFor(d) ?? 0;
        return Expanded(child: GestureDetector(
          onTap: () => onChanged(sel ? null : d),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? AppColors.accent : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? AppColors.accent : AppColors.border),
            ),
            child: Column(children: [
              Text(d.label, style: TextStyle(
                  color: sel ? Colors.black : AppColors.text,
                  fontWeight: FontWeight.w700, fontSize: 13)),
              Text('\$${r.toStringAsFixed(0)}/sqft',
                  style: TextStyle(
                      color: sel ? Colors.black87 : AppColors.muted,
                      fontSize: 10)),
            ]),
          ),
        ));
      }).toList()),
    ]);
  }
}

// ─── Toggle Chip ──────────────────────────────────────────────────────────────
class ToggleChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const ToggleChip({super.key, required this.label, required this.value,
      required this.onChanged, this.activeColor});

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.accent;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: value ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: value ? color : AppColors.border),
        ),
        child: Text(label, style: TextStyle(
            color: value ? Colors.black : AppColors.muted,
            fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }
}

// ─── Step Counter ─────────────────────────────────────────────────────────────
class StepCounter extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const StepCounter({super.key, required this.label, required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: FieldLabel(label)),
      GestureDetector(
        onTap: () { if (value > 0) onChanged(value - 1); },
        child: Container(width: 32, height: 32,
            decoration: BoxDecoration(color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border)),
            child: const Icon(Icons.remove, color: AppColors.muted, size: 16)),
      ),
      Container(width: 44, alignment: Alignment.center,
          child: Text('$value', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
      GestureDetector(
        onTap: () => onChanged(value + 1),
        child: Container(width: 32, height: 32,
            decoration: BoxDecoration(color: AppColors.accent,
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.add, color: Colors.black, size: 16)),
      ),
    ],
  );
}

// ─── Photo Picker ─────────────────────────────────────────────────────────────
class PhotoPickerWidget extends StatelessWidget {
  final String? photoPath;
  final ValueChanged<String?> onChanged;
  final String label;

  const PhotoPickerWidget({super.key, this.photoPath, required this.onChanged,
      this.label = 'Add Photo'});

  Future<void> _pick() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (xFile != null) onChanged(xFile.path);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;
    if (hasPhoto) {
      return Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(File(photoPath!), width: 60, height: 60, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 60, height: 60,
                  color: AppColors.surface,
                  child: const Icon(Icons.broken_image, color: AppColors.muted))),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(onTap: _pick,
              child: const Text('Change Photo',
                  style: TextStyle(color: AppColors.accent, fontSize: 13))),
          const SizedBox(height: 4),
          GestureDetector(onTap: () => onChanged(null),
              child: const Text('Remove',
                  style: TextStyle(color: AppColors.danger, fontSize: 12))),
        ]),
      ]);
    }
    return GestureDetector(
      onTap: _pick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border,
              style: BorderStyle.solid),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.camera_alt_outlined, color: AppColors.muted, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        ]),
      ),
    );
  }
}

// ─── Grout Section ────────────────────────────────────────────────────────────
class GroutSectionWidget extends StatelessWidget {
  final String surfaceLabel;
  final GroutData data;
  final double groutPrice;
  final ValueChanged<GroutData> onChanged;

  const GroutSectionWidget({super.key, required this.surfaceLabel,
      required this.data, required this.groutPrice, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bags = int.tryParse(data.bags) ?? 0;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Row(children: [
        const Text('Grout', style: TextStyle(color: AppColors.muted,
            fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        if (bags > 0) Text('$bags bags · \$${(bags * groutPrice).toStringAsFixed(2)}',
            style: const TextStyle(color: AppColors.teal, fontSize: 11)),
        if (data.color.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text('· ${data.color}',
              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        ],
      ]),
      iconColor: AppColors.muted,
      collapsedIconColor: AppColors.muted,
      children: [
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 100, child: AppInput(label: 'Bags', isNumber: true,
              value: data.bags,
              onChanged: (v) => onChanged(data..bags = v))),
          const SizedBox(width: 10),
          Expanded(child: AppInput(label: 'Color (optional)',
              value: data.color,
              onChanged: (v) => onChanged(data..color = v))),
        ]),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─── Confirmation Dialog ──────────────────────────────────────────────────────
Future<bool> showConfirmDialog(BuildContext context,
    {required String title, required String message,
    String confirmLabel = 'Delete', Color confirmColor = AppColors.danger}) async {
  return await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
      content: Text(message, style: const TextStyle(color: AppColors.muted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
        TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel, style: TextStyle(color: confirmColor, fontWeight: FontWeight.w700))),
      ],
    ),
  ) ?? false;
}

// ─── Primary Button ───────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const PrimaryButton({super.key, required this.label, this.onTap, this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.accent,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
    ),
  );
}

// ─── Cost Row ─────────────────────────────────────────────────────────────────
class CostRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;
  final bool bold;

  const CostRow({super.key, required this.label, required this.amount,
      this.color, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
            color: bold ? AppColors.text : AppColors.muted,
            fontSize: bold ? 14 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        Text('\$${amount.toStringAsFixed(2)}', style: TextStyle(
            color: color ?? AppColors.text,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            fontSize: bold ? 15 : 14)),
      ],
    ),
  );
}

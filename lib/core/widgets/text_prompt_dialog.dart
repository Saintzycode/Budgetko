import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A single field dialog that owns its own [TextEditingController].
///
/// Owning the controller is the whole point of this widget. Disposing a
/// controller from the `showDialog` future, whether by `await` or by
/// `whenComplete`, happens at pop time while the route is still running
/// its exit animation and the field is still listening to it, which
/// throws "A TextEditingController was used after being disposed".
/// Disposing from this widget's own `dispose` runs after the route has
/// fully torn the subtree down.
class TextPromptDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String cancelLabel;
  final String? initialValue;
  final String? hintText;
  final String? prefixText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final Color? confirmBackground;
  final String? extraActionLabel;
  final VoidCallback? onExtraAction;

  const TextPromptDialog({
    super.key,
    required this.title,
    this.confirmLabel = 'Save',
    this.cancelLabel = 'Cancel',
    this.initialValue,
    this.hintText,
    this.prefixText,
    this.keyboardType = const TextInputType.numberWithOptions(
      decimal: true,
    ),
    this.textCapitalization = TextCapitalization.none,
    this.confirmBackground,
    this.extraActionLabel,
    this.onExtraAction,
  });

  /// Shows the dialog and returns the trimmed text, or null if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    String confirmLabel = 'Save',
    String cancelLabel = 'Cancel',
    String? initialValue,
    String? hintText,
    String? prefixText,
    TextInputType keyboardType =
        const TextInputType.numberWithOptions(decimal: true),
    TextCapitalization textCapitalization = TextCapitalization.none,
    Color? confirmBackground,
    String? extraActionLabel,
    VoidCallback? onExtraAction,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => TextPromptDialog(
        title: title,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        initialValue: initialValue,
        hintText: hintText,
        prefixText: prefixText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        confirmBackground: confirmBackground,
        extraActionLabel: extraActionLabel,
        onExtraAction: onExtraAction,
      ),
    );
  }

  @override
  State<TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<TextPromptDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: Text(
        widget.title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixText: widget.prefixText,
          hintStyle: const TextStyle(color: AppColors.textHint),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        if (widget.extraActionLabel != null && widget.onExtraAction != null)
          TextButton(
            onPressed: () {
              widget.onExtraAction!();
              Navigator.of(context).pop();
            },
            child: Text(
              widget.extraActionLabel!,
              style: const TextStyle(color: AppColors.expense),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            widget.cancelLabel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: widget.confirmBackground == null
              ? null
              : ElevatedButton.styleFrom(
                  backgroundColor: widget.confirmBackground,
                ),
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

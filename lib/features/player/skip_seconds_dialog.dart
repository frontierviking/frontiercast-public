import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/playback_settings.dart';

/// Shows a preset list of skip intervals plus a "Custom…" entry for an
/// arbitrary number of seconds. Returns the chosen seconds, or null if
/// cancelled.
Future<int?> showSkipSecondsDialog(
  BuildContext context, {
  required String title,
  required int current,
}) async {
  final choice = await showDialog<Object>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(title),
      children: [
        for (final s in skipSecondOptions)
          ListTile(
            title: Text('$s seconds'),
            trailing: s == current
                ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                : null,
            onTap: () => Navigator.of(ctx).pop(s),
          ),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Custom…'),
          onTap: () => Navigator.of(ctx).pop('custom'),
        ),
      ],
    ),
  );

  if (choice is int) return choice;
  if (choice != 'custom') return null;

  if (!context.mounted) return null;
  final controller = TextEditingController(text: '$current');
  final custom = await showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Custom seconds'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(suffixText: 'seconds'),
        onSubmitted: (v) => Navigator.of(ctx).pop(int.tryParse(v.trim())),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(ctx).pop(int.tryParse(controller.text.trim())),
          child: const Text('Set'),
        ),
      ],
    ),
  );
  if (custom == null || custom <= 0) return null;
  return custom.clamp(1, 600);
}

import 'package:flutter/material.dart';

import '../../app/app_visuals.dart';

Future<bool> confirmDeleteMemoryRecord({
  required BuildContext context,
  required String title,
  required String content,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      icon: Container(
        width: 68,
        height: 68,
        decoration: const BoxDecoration(
          color: Color(0xFFFFE9ED),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
          size: 36,
        ),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Text(
        content,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textMuted, height: 1.5),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      actions: [
        SizedBox(
          width: 120,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认删除'),
          ),
        ),
      ],
    ),
  );

  return result ?? false;
}

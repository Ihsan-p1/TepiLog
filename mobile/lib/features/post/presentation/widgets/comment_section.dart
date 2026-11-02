import 'package:flutter/material.dart';

/// Comments as a conversation: oldest first, the name in bold before the
/// text. [comments] is the raw API list, newest first.
class CommentList extends StatelessWidget {
  const CommentList({super.key, required this.comments});

  final List<dynamic> comments;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (comments.isEmpty) {
      return Text('Belum ada komentar. Tulis yang pertama di bawah.', style: text.bodySmall);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in comments.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '${c['user']?['username'] ?? 'pengguna'}  ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: '${c['body'] ?? ''}'),
              ]),
              style: text.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
            ),
          ),
      ],
    );
  }
}

/// The comment field pinned above the keyboard. The send button stays muted
/// and off until there is something to send.
class CommentInput extends StatelessWidget {
  const CommentInput({
    super.key,
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 0, 0, 0),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Tulis komentar…',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final ready = value.text.trim().isNotEmpty && !sending;
              return IconButton.filled(
                tooltip: 'Kirim komentar',
                onPressed: ready ? onSend : null,
                style: IconButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  disabledBackgroundColor: scheme.surfaceContainerHighest,
                  disabledForegroundColor: scheme.onSurfaceVariant,
                  // A 40 dp disc inside the 48 dp touch target.
                  minimumSize: const Size(40, 40),
                  fixedSize: const Size(40, 40),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                icon: sending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onSurfaceVariant),
                      )
                    : const Icon(Icons.arrow_upward_rounded, size: 20),
              );
            },
          ),
        ],
      ),
    );
  }
}

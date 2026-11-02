import 'package:flutter/material.dart';

class CreateFolderDialog extends StatefulWidget {
  final String? initialName;
  final bool isRename;

  const CreateFolderDialog({
    super.key,
    this.initialName,
    this.isRename = false,
  });

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.isRename ? 'Rename Folder' : 'New Folder'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Folder name...',
          prefixIcon: const Icon(Icons.folder_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              Navigator.pop(context, text);
            }
          },
          child: Text(widget.isRename ? 'Rename' : 'Create'),
        ),
      ],
    );
  }
}

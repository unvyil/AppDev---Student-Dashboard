import 'package:flutter/material.dart';

import 'services/file_service.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  late Future<String> _fileContent;
  late Future<String> _filePath;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  void _loadFile() {
    _fileContent = FileService.readExportedFile();
    _filePath = FileService.getFilePath();
  }

  Future<void> _exportFile() async {
    setState(() => _exporting = true);

    try {
      await FileService.exportStudents();

      if (!mounted) return;

      setState(_loadFile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student file exported successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Generated Files',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Export and view your saved student information.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 20),

        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.description_outlined),
            ),
            title: const Text('student_info.txt'),
            subtitle: const Text('Plain-text student information export'),
            trailing: const Icon(Icons.insert_drive_file_outlined),
          ),
        ),

        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _exporting ? null : _exportFile,
          icon: const Icon(Icons.file_download_outlined),
          label: Text(
            _exporting ? 'Exporting...' : 'Export Student Information',
          ),
        ),

        const SizedBox(height: 20),
        const Text(
          'File Location',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        FutureBuilder<String>(
          future: _filePath,
          builder: (context, snapshot) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  snapshot.data ?? 'Loading file location...',
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),
        const Text(
          'File Contents',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        FutureBuilder<String>(
          future: _fileContent,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Text('Unable to read the generated file.');
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  snapshot.data ?? 'No file contents available.',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

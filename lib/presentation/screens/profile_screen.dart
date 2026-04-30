import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gym_log/data/services/import_export_service.dart';
import 'package:gym_log/presentation/screens/routines_list_screen.dart';
import 'package:gym_log/presentation/screens/exercise_catalog_screen.dart';
import 'package:gym_log/presentation/screens/user_profile_detail_screen.dart';
import 'package:gym_log/presentation/screens/bia_reports_list_screen.dart';
import 'package:gym_log/presentation/screens/weight_history_screen.dart';
import 'package:gym_log/presentation/screens/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImportExportService _importExportService = ImportExportService();
  bool _isLoading = false;

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    try {
      final jsonString = await _importExportService.exportData();

      // Write to a temp file then share it via the native share sheet
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/gym_log_export.json');
      await file.writeAsString(jsonString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'Gym Log Data Export',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: \$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importData() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      
      bool? override = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Import Data'),
            content: const Text('How would you like to import the data?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Add from data (Merge)'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Override all data', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(null), // Cancel
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (override != null) {
        setState(() => _isLoading = true);
        try {
          final file = File(result.files.single.path!);
          final jsonString = await file.readAsString();
          
          final success = await _importExportService.importData(jsonString, override: override);
          
          if (mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data imported successfully! Please restart the app or refresh screens to see changes.')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to import data. Invalid format.')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Import error: \$e')),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            children: [
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileDetailScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Weight History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WeightHistoryScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.monitor_weight_outlined),
            title: const Text('Body Composition'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BiaReportsListScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Workout Routines'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RoutinesListScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('Exercise Catalog'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExerciseCatalogScreen(isSelectionMode: false),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          // Export Data
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export Data'),
            trailing: const Icon(Icons.download),
            onTap: _exportData,
          ),
          // Import Data
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Import Data'),
            trailing: const Icon(Icons.upload),
            onTap: _importData,
          ),
        ],
      ),
    );
  }
}

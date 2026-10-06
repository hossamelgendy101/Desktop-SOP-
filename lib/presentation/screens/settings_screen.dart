import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/locale_service.dart';
import '../../services/backup_service.dart';
import '../../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoBackupEnabled = true;

  String _text(String en, String ar) {
    return context.read<LocaleService>().locale.languageCode == 'ar' ? ar : en;
  }

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    final themeService = context.watch<ThemeService>();

    return Scaffold(
      appBar: AppBar(title: Text(_text('Settings', 'الإعدادات'))),
      body: ListView(
        children: [
          _buildSectionHeader(context, _text('General', 'عام')),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(_text('Language', 'اللغة')),
            subtitle: Text(localeService.locale.languageCode == 'ar' ? 'العربية' : 'English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: Text(_text('Theme', 'المظهر')),
            subtitle: Text(themeService.themeMode == ThemeMode.dark
                ? _text('Dark', 'داكن')
                : themeService.themeMode == ThemeMode.light
                    ? _text('Light', 'فاتح')
                    : _text('System Default', 'الوضع الافتراضي')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context),
          ),
          _buildSectionHeader(context, _text('Store', 'المتجر')),
          ListTile(
            leading: const Icon(Icons.store),
            title: Text(_text('Store Information', 'معلومات المتجر')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showStoreInfoDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: Text(_text('Receipt Settings', 'إعدادات الإيصال')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showReceiptSettingsDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.print),
            title: Text(_text('Printer Settings', 'إعدادات الطابعة')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPrinterSettingsDialog(context),
          ),
          _buildSectionHeader(context, _text('Data', 'البيانات')),
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text(_text('Backup Database', 'نسخ قاعدة البيانات')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _createBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(_text('Restore Database', 'استعادة قاعدة البيانات')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _restoreBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.auto_fix_high),
            title: Text(_text('Auto Backup', 'النسخ الاحتياطي التلقائي')),
            subtitle: Text(_text('Daily at 2:00 AM', 'يومياً في 2:00 صباحاً')),
            trailing: Switch(
              value: _autoBackupEnabled,
              onChanged: (v) => _toggleAutoBackup(context, v),
            ),
          ),
          _buildSectionHeader(context, _text('System', 'النظام')),
          ListTile(
            leading: const Icon(Icons.security),
            title: Text(_text('Security', 'الأمان')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSecurityDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: Text(_text('User Management', 'إدارة المستخدمين')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUserManagementDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(_text('About', 'حول')),
            subtitle: const Text('ProPOS v1.0.0'),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              )),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: LocaleService().locale.languageCode == 'en' ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                context.read<LocaleService>().setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('العربية'),
              trailing: LocaleService().locale.languageCode == 'ar' ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                context.read<LocaleService>().setLocale(const Locale('ar'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    try {
      final path = await BackupService().createBackup();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup created: $path')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    try {
      await BackupService().restoreBackup();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Database restored successfully. Please restart the app.')));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  void _showThemeDialog(BuildContext context) {
    final themeService = context.read<ThemeService>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System Default'),
              trailing: themeService.themeMode == ThemeMode.system ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                themeService.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Light'),
              trailing: themeService.themeMode == ThemeMode.light ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                themeService.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Dark'),
              trailing: themeService.themeMode == ThemeMode.dark ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                themeService.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStoreInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Store Information'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: InputDecoration(labelText: 'Store Name', hintText: 'My Store')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(labelText: 'Address', hintText: 'Main Street')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(labelText: 'Phone', hintText: '+1234567890')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(labelText: 'Email', hintText: 'store@example.com')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(labelText: 'Tax Number', hintText: 'TAX123')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }

  void _showReceiptSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receipt Settings'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: InputDecoration(labelText: 'Receipt Width (mm)', hintText: '80')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(labelText: 'Receipt Footer', hintText: 'Thank you for your purchase')),
              SizedBox(height: 12),
              CheckboxListTile(
                value: true,
                onChanged: null,
                title: Text('Print logo on receipt'),
              ),
              CheckboxListTile(
                value: true,
                onChanged: null,
                title: Text('Print customer info'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }

  void _showPrinterSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Printer Settings'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: InputDecoration(labelText: 'Printer Name', hintText: 'USB Printer')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(labelText: 'Paper Width (mm)', hintText: '80')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }

  void _toggleAutoBackup(BuildContext context, bool value) {
    setState(() {
      _autoBackupEnabled = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Auto Backup ${value ? 'enabled' : 'disabled'}')),
    );
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Settings'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: true,
                onChanged: null,
                title: Text('Require password on startup'),
              ),
              CheckboxListTile(
                value: false,
                onChanged: null,
                title: Text('Lock after 5 minutes of inactivity'),
              ),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(labelText: 'Change Password', hintText: 'New password')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }

  void _showUserManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Management'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('admin'),
                subtitle: Text('Administrator'),
                trailing: Icon(Icons.edit),
              ),
              Divider(),
              TextField(decoration: InputDecoration(labelText: 'Add New User', hintText: 'Username')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Add User')),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'ProPOS',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 ProPOS. All rights reserved.',
      children: [
        const Text('A professional Point of Sale system for retail businesses.'),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Product Management'),
        const Text('• Sales Tracking'),
        const Text('• Inventory Management'),
        const Text('• Reports & Analytics'),
        const Text('• Multi-language Support'),
      ],
    );
  }
}

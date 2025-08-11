import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _biometricEnabled = true;
  bool _pinEnabled = true;
  bool _autoLockEnabled = true;
  int _autoLockDelay = 5; // minutes
  bool _cloudSyncEnabled = true;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'de';
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final securityProvider = context.read<SecurityProvider>();
    final authProvider = context.read<AuthProvider>();
    
    // Load settings from providers
    setState(() {
      _biometricEnabled = securityProvider.isBiometricEnabled;
      _pinEnabled = securityProvider.isPinEnabled;
      _autoLockEnabled = securityProvider.isAutoLockEnabled;
      _autoLockDelay = securityProvider.autoLockDelay;
      _cloudSyncEnabled = authProvider.isCloudSyncEnabled;
      _notificationsEnabled = authProvider.isNotificationsEnabled;
      _selectedLanguage = authProvider.selectedLanguage;
      _darkModeEnabled = authProvider.isDarkModeEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Einstellungen',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Security Section
          _buildSectionHeader('Sicherheit', Icons.security),
          _buildSecuritySettings(),
          
          const SizedBox(height: 24),
          
          // Privacy Section
          _buildSectionHeader('Datenschutz', Icons.privacy_tip),
          _buildPrivacySettings(),
          
          const SizedBox(height: 24),
          
          // App Section
          _buildSectionHeader('App', Icons.settings),
          _buildAppSettings(),
          
          const SizedBox(height: 24),
          
          // Account Section
          _buildSectionHeader('Konto', Icons.account_circle),
          _buildAccountSettings(),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSectionHeader('Über', Icons.info),
          _buildAboutSettings(),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Column(
      children: [
        _buildSwitchTile(
          title: 'Biometrische Authentifizierung',
          subtitle: 'Fingerabdruck oder Gesichtserkennung verwenden',
          value: _biometricEnabled,
          onChanged: (value) {
            setState(() {
              _biometricEnabled = value;
            });
            _updateBiometricSetting(value);
          },
        ),
        
        _buildSwitchTile(
          title: 'PIN-Authentifizierung',
          subtitle: '6-stellige PIN für App-Entsperrung',
          value: _pinEnabled,
          onChanged: (value) {
            setState(() {
              _pinEnabled = value;
            });
            _updatePinSetting(value);
          },
        ),
        
        _buildSwitchTile(
          title: 'Automatische Sperre',
          subtitle: 'App nach Inaktivität automatisch sperren',
          value: _autoLockEnabled,
          onChanged: (value) {
            setState(() {
              _autoLockEnabled = value;
            });
            _updateAutoLockSetting(value);
          },
        ),
        
        if (_autoLockEnabled) ...[
          const SizedBox(height: 16),
          _buildSliderTile(
            title: 'Sperrverzögerung',
            subtitle: '$_autoLockDelay Minuten',
            value: _autoLockDelay.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            onChanged: (value) {
              setState(() {
                _autoLockDelay = value.round();
              });
              _updateAutoLockDelay(value.round());
            },
          ),
        ],
        
        const SizedBox(height: 16),
        
        _buildButtonTile(
          title: 'PIN ändern',
          subtitle: 'Aktuelle PIN ändern',
          icon: Icons.edit,
          onTap: _changePin,
        ),
        
        _buildButtonTile(
          title: 'Sicherheitsbericht',
          subtitle: 'Letzte Anmeldungen und Aktivitäten',
          icon: Icons.assessment,
          onTap: _showSecurityReport,
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return Column(
      children: [
        _buildSwitchTile(
          title: 'Cloud-Synchronisation',
          subtitle: 'Dateien mit der Cloud synchronisieren',
          value: _cloudSyncEnabled,
          onChanged: (value) {
            setState(() {
              _cloudSyncEnabled = value;
            });
            _updateCloudSyncSetting(value);
          },
        ),
        
        _buildSwitchTile(
          title: 'Benachrichtigungen',
          subtitle: 'Push-Benachrichtigungen erhalten',
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
            _updateNotificationsSetting(value);
          },
        ),
        
        const SizedBox(height: 16),
        
        _buildButtonTile(
          title: 'Daten exportieren',
          subtitle: 'Alle Daten als Backup exportieren',
          icon: Icons.download,
          onTap: _exportData,
        ),
        
        _buildButtonTile(
          title: 'Daten löschen',
          subtitle: 'Alle lokalen Daten unwiderruflich löschen',
          icon: Icons.delete_forever,
          onTap: _deleteAllData,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildAppSettings() {
    return Column(
      children: [
        _buildDropdownTile(
          title: 'Sprache',
          subtitle: _getLanguageDisplayName(_selectedLanguage),
          value: _selectedLanguage,
          items: const [
            DropdownMenuItem(value: 'de', child: Text('Deutsch')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedLanguage = value;
              });
              _updateLanguageSetting(value);
            }
          },
        ),
        
        _buildSwitchTile(
          title: 'Dunkler Modus',
          subtitle: 'App im dunklen Design anzeigen',
          value: _darkModeEnabled,
          onChanged: (value) {
            setState(() {
              _darkModeEnabled = value;
            });
            _updateDarkModeSetting(value);
          },
        ),
        
        const SizedBox(height: 16),
        
        _buildButtonTile(
          title: 'Cache leeren',
          subtitle: 'Temporäre Dateien löschen',
          icon: Icons.cleaning_services,
          onTap: _clearCache,
        ),
        
        _buildButtonTile(
          title: 'App zurücksetzen',
          subtitle: 'Alle Einstellungen auf Standard zurücksetzen',
          icon: Icons.restore,
          onTap: _resetApp,
        ),
      ],
    );
  }

  Widget _buildAccountSettings() {
    return Column(
      children: [
        _buildInfoTile(
          title: 'E-Mail',
          subtitle: 'user@example.com', // TODO: Get from auth provider
          icon: Icons.email,
        ),
        
        _buildInfoTile(
          title: 'Mitglied seit',
          subtitle: 'Januar 2024', // TODO: Get from auth provider
          icon: Icons.calendar_today,
        ),
        
        const SizedBox(height: 16),
        
        _buildButtonTile(
          title: 'Profil bearbeiten',
          subtitle: 'Persönliche Informationen ändern',
          icon: Icons.edit,
          onTap: _editProfile,
        ),
        
        _buildButtonTile(
          title: 'Passwort ändern',
          subtitle: 'Aktuelles Passwort ändern',
          icon: Icons.lock,
          onTap: _changePassword,
        ),
        
        _buildButtonTile(
          title: 'Zwei-Faktor-Authentifizierung',
          subtitle: 'Zusätzliche Sicherheit aktivieren',
          icon: Icons.verified_user,
          onTap: _setupTwoFactor,
        ),
      ],
    );
  }

  Widget _buildAboutSettings() {
    return Column(
      children: [
        _buildInfoTile(
          title: 'Version',
          subtitle: '1.0.0',
          icon: Icons.info,
        ),
        
        _buildInfoTile(
          title: 'Build',
          subtitle: '2024.01.001',
          icon: Icons.build,
        ),
        
        const SizedBox(height: 16),
        
        _buildButtonTile(
          title: 'Lizenz',
          subtitle: 'Open Source Lizenz anzeigen',
          icon: Icons.description,
          onTap: _showLicense,
        ),
        
        _buildButtonTile(
          title: 'Datenschutzerklärung',
          subtitle: 'Wie wir Ihre Daten schützen',
          icon: Icons.privacy_tip,
          onTap: _showPrivacyPolicy,
        ),
        
        _buildButtonTile(
          title: 'Nutzungsbedingungen',
          subtitle: 'Richtlinien für die App-Nutzung',
          icon: Icons.rule,
          onTap: _showTerms,
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title),
              Text(subtitle),
            ],
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: Container(),
      ),
    );
  }

  Widget _buildButtonTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppTheme.errorColor : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppTheme.errorColor : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  String _getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'de':
        return 'Deutsch';
      case 'en':
        return 'English';
      default:
        return 'Deutsch';
    }
  }

  // Settings update methods
  void _updateBiometricSetting(bool value) {
    final securityProvider = context.read<SecurityProvider>();
    securityProvider.setBiometricEnabled(value);
  }

  void _updatePinSetting(bool value) {
    final securityProvider = context.read<SecurityProvider>();
    securityProvider.setPinEnabled(value);
  }

  void _updateAutoLockSetting(bool value) {
    final securityProvider = context.read<SecurityProvider>();
    securityProvider.setAutoLockEnabled(value);
  }

  void _updateAutoLockDelay(int delay) {
    final securityProvider = context.read<SecurityProvider>();
    securityProvider.setAutoLockDelay(delay);
  }

  void _updateCloudSyncSetting(bool value) {
    final authProvider = context.read<AuthProvider>();
    authProvider.setCloudSyncEnabled(value);
  }

  void _updateNotificationsSetting(bool value) {
    final authProvider = context.read<AuthProvider>();
    authProvider.setNotificationsEnabled(value);
  }

  void _updateLanguageSetting(String language) {
    final authProvider = context.read<AuthProvider>();
    authProvider.setLanguage(language);
  }

  void _updateDarkModeSetting(bool value) {
    final authProvider = context.read<AuthProvider>();
    authProvider.setDarkMode(value);
  }

  // Action methods
  void _changePin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PIN ändern'),
        content: const Text('Diese Funktion wird in einer zukünftigen Version verfügbar sein.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSecurityReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sicherheitsbericht'),
        content: const Text('Letzte Anmeldungen und Aktivitäten werden hier angezeigt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daten exportieren'),
        content: const Text('Diese Funktion wird in einer zukünftigen Version verfügbar sein.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _deleteAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle Daten löschen'),
        content: const Text('Sind Sie sicher, dass Sie alle Daten unwiderruflich löschen möchten?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final securityProvider = context.read<SecurityProvider>();
              securityProvider.clearAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alle Daten wurden gelöscht')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache leeren'),
        content: const Text('Cache wurde erfolgreich geleert.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App zurücksetzen'),
        content: const Text('Sind Sie sicher, dass Sie alle Einstellungen zurücksetzen möchten?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Reset all settings to defaults
              final securityProvider = context.read<SecurityProvider>();
              final authProvider = context.read<AuthProvider>();
              
              // Reset security settings
              securityProvider.setBiometricEnabled(false);
              securityProvider.setPinEnabled(false);
              securityProvider.setAutoLockEnabled(false);
              securityProvider.setAutoLockDelay(5);
              
              // Reset app settings
              authProvider.setCloudSyncEnabled(false);
              authProvider.setNotificationsEnabled(true);
              authProvider.setLanguage('de');
              authProvider.setDarkMode(false);
              
              // Reload settings
              _loadSettings();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App wurde zurückgesetzt')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil bearbeiten'),
        content: const Text('Diese Funktion wird in einer zukünftigen Version verfügbar sein.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Passwort ändern'),
        content: const Text('Diese Funktion wird in einer zukünftigen Version verfügbar sein.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _setupTwoFactor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zwei-Faktor-Authentifizierung'),
        content: const Text('Diese Funktion wird in einer zukünftigen Version verfügbar sein.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLicense() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lizenz'),
        content: const Text('SecureFolder v1.0.0\n\nAlle Rechte vorbehalten.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Datenschutzerklärung'),
        content: const Text('Ihre Daten werden sicher verschlüsselt und nur lokal auf Ihrem Gerät gespeichert.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nutzungsbedingungen'),
        content: const Text('Durch die Nutzung dieser App stimmen Sie unseren Nutzungsbedingungen zu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String userName = "";
  String userEmail = "";
  String userPhone = "";
  bool isLoadingProfile = true;

  // controllers for edit profile
  final nameController = TextEditingController();
  // controllers for change password
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController = TextEditingController();

  bool showCurrentPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
    // Load saved dark mode preference
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ThemeProvider>(context, listen: false).loadTheme();
    });
  }

  Future<void> loadProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        setState(() {
          userName  = doc.data()!['name']  ?? "";
          userEmail = doc.data()!['email'] ?? "";
          userPhone = doc.data()!['phone'] ?? "";
          nameController.text = userName;
          isLoadingProfile = false;
        });
      }
    } catch (_) {
      setState(() => isLoadingProfile = false);
    }
  }

  // ── Edit Profile Dialog ──────────────────────────────────
  void showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A6BFF)),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              try {
                final uid = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'name': nameController.text.trim()});
                setState(() => userName = nameController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Profile updated!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Change Password Dialog ───────────────────────────────
  void showChangePasswordDialog() {
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmNewPasswordController.clear();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current password
                TextField(
                  controller: currentPasswordController,
                  obscureText: !showCurrentPassword,
                  decoration: InputDecoration(
                    labelText: "Current Password",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(showCurrentPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => showCurrentPassword = !showCurrentPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // New password
                TextField(
                  controller: newPasswordController,
                  obscureText: !showNewPassword,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(showNewPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => showNewPassword = !showNewPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Confirm new password
                TextField(
                  controller: confirmNewPasswordController,
                  obscureText: !showConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Confirm New Password",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => showConfirmPassword = !showConfirmPassword),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A6BFF)),
              onPressed: () async {
                if (newPasswordController.text != confirmNewPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("❌ Passwords don't match")));
                  return;
                }
                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("❌ Min 6 characters")));
                  return;
                }
                try {
                  final user = FirebaseAuth.instance.currentUser!;
                  // Re-authenticate first
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPasswordController.text.trim(),
                  );
                  await user.reauthenticateWithCredential(cred);
                  // Then update password
                  await user.updatePassword(newPasswordController.text.trim());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Password changed!")));
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("❌ ${e.message}")));
                }
              },
              child: const Text("Change", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sign Out ─────────────────────────────────────────────
  void signOut() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const FrontWidget()),
                  (route) => false,
                );
              }
            },
            child: const Text("Sign Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Profile Card ─────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF1A6BFF), Color(0xFF00C896)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : "?",
                            style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(userEmail,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              if (userPhone.isNotEmpty)
                                Text(userPhone,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Appearance ───────────────────────────
                  _sectionLabel("🎨 Appearance"),
                  _settingsTile(
                    icon: isDark ? Icons.dark_mode : Icons.light_mode,
                    iconColor: isDark ? Colors.indigo : Colors.orange,
                    title: "Dark Mode",
                    subtitle: isDark ? "Dark theme is ON" : "Light theme is ON",
                    trailing: Switch(
                      value: isDark,
                      activeColor: const Color(0xFF1A6BFF),
                      onChanged: (_) => themeProvider.toggleTheme(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Account ──────────────────────────────
                  _sectionLabel("👤 Account"),
                  _settingsTile(
                    icon: Icons.edit,
                    iconColor: const Color(0xFF1A6BFF),
                    title: "Edit Profile",
                    subtitle: "Change your username",
                    trailing: const Icon(Icons.chevron_right),
                    onTap: showEditProfileDialog,
                  ),
                  _settingsTile(
                    icon: Icons.lock_outline,
                    iconColor: Colors.green,
                    title: "Change Password",
                    subtitle: "Update your password",
                    trailing: const Icon(Icons.chevron_right),
                    onTap: showChangePasswordDialog,
                  ),

                  const SizedBox(height: 16),

                  // ── Danger Zone ──────────────────────────
                  _sectionLabel("⚠️ Account Actions"),
                  _settingsTile(
                    icon: Icons.logout,
                    iconColor: Colors.red,
                    title: "Sign Out",
                    subtitle: "Log out of your account",
                    trailing: const Icon(Icons.chevron_right, color: Colors.red),
                    onTap: signOut,
                  ),

                  const SizedBox(height: 30),

                  // App version
                  Center(
                    child: Text(
                      "SpendSense v1.0.0",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
      );

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: trailing,
      ),
    );
  }
}
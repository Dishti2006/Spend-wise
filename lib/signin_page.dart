import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard.dart';
import 'signup_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool showPassword = false;

  // ─────────────────────────────────────────────
  // SIGN IN
  // ─────────────────────────────────────────────
  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Sign in directly without an unauthenticated Firestore lookup.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Login successful → Dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const Dashboard(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;

      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        message = "❌ Incorrect email or password";
      } else if (e.code == 'invalid-email') {
        message = "❌ Invalid email";
      } else if (e.code == 'user-disabled') {
        message = "❌ This account has been disabled";
      } else {
        message = "❌ ${e.message ?? 'Login failed'}";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: $e"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ─────────────────────────────────────────────
  // FORGOT PASSWORD
  // ─────────────────────────────────────────────
  void showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Forgot Password",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your registered Gmail. We'll send a password reset link to your email.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Gmail",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          // CANCEL
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          // SEND RESET LINK
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A6BFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final email = emailController.text.trim();

              // Check empty email
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("❌ Enter your email"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Check Gmail format
              if (!email.contains("@gmail.com")) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("❌ Enter a valid Gmail address"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                // Send password reset email directly through Firebase
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: email,
                );

                if (!mounted) return;

                // Close forgot password dialog
                Navigator.pop(context);

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "✅ Reset link sent! Check your Gmail inbox and Spam folder.",
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 5),
                  ),
                );

                // Open reset waiting screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResetPasswordWaitingScreen(
                      email: email,
                    ),
                  ),
                );
              } on FirebaseAuthException catch (e) {
                String message;

                if (e.code == 'user-not-found') {
                  message =

                      "❌ No Firebase account exists with this Gmail";
                } else if (e.code == 'invalid-email') {
                  message = "❌ Invalid Gmail address";
                } else if (e.code == 'too-many-requests') {
                  message =
                      "❌ Too many requests. Try again later.";
                } else {
                  message =
                      "❌ ${e.message ?? 'Could not send reset email'}";
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("❌ Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Send Reset Link",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD SIGN IN PAGE
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 31, 31, 182),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 199, 199, 210),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Sign In",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(25),

        child: Form(
          key: formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // WELCOME
              const Text(
                "Welcome Back 👋",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "Sign in to continue",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              // EMAIL
              const Text(
                "Email",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],

                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  hintText: "Enter your email",
                ),

                validator: (v) {
                  final email = v?.trim() ?? '';
                  if (email.isEmpty) return "Enter your email";
                  if (!email.contains('@')) return "Enter a valid email";
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // PASSWORD
              const Text(
                "Password",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: passwordController,

                obscureText: !showPassword,

                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: const OutlineInputBorder(),
                  hintText: "Enter your password",

                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),

                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                ),

                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return "Enter password";
                  }

                  if (v.length < 6) {
                    return "Min 6 characters";
                  }

                  return null;
                },
              ),

              // FORGOT PASSWORD
              Align(
                alignment: Alignment.centerRight,

                child: TextButton(
                  onPressed: showForgotPasswordDialog,

                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // SIGN IN BUTTON
              GestureDetector(
                onTap: isLoading ? null : signIn,

                child: Container(
                  width: double.infinity,
                  height: 50,

                  color: Colors.blue,

                  child: Center(
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Sign In",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),

              // CREATE ACCOUNT
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignUpPage(),
                        ),
                      );
                    },

                    child: const Text(
                      "Create Account",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RESET PASSWORD WAITING SCREEN
// ─────────────────────────────────────────────

class ResetPasswordWaitingScreen extends StatelessWidget {
  final String email;

  const ResetPasswordWaitingScreen({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 31, 31, 182),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 199, 199, 210),

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),

          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          "Reset Password",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            // EMAIL ICON
            Container(
              width: 100,
              height: 100,

              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 50,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            // TITLE
            const Text(
              "Check Your Email!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // EMAIL
            Text(
              "We sent a password reset link to:\n$email",
              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Open your email → click the link → set new password → come back and sign in!",
              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 40),

            // RESEND EMAIL
            GestureDetector(
              onTap: () async {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: email,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Reset link resent!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "❌ ${e.message ?? 'Could not resend email'}",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("❌ Error: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },

              child: Container(
                width: double.infinity,
                height: 50,

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white30,
                  ),
                ),

                child: const Center(
                  child: Text(
                    "Resend Email",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // BACK TO SIGN IN
            GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,

                  MaterialPageRoute(
                    builder: (_) => const SignInPage(),
                  ),

                  (route) => false,
                );
              },

              child: Container(
                width: double.infinity,
                height: 50,

                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),

                child: const Center(
                  child: Text(
                    "Back to Sign In",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

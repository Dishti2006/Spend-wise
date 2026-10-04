import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signin_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final usernameController = TextEditingController();
  final gmailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  // ─────────────────────────────────────────────
  // CREATE ACCOUNT
  // ─────────────────────────────────────────────
  Future<void> createAccount() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Create account in Firebase Authentication
      final cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: gmailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Store additional user information in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'name': usernameController.text.trim(),
        'email': gmailController.text.trim(),
        'phone': phoneController.text.trim(),
        'createdAt': DateTime.now().toString(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Account Created Successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // Go to Sign In page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SignInPage(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;

      if (e.code == 'email-already-in-use') {
        message = "❌ This Gmail is already registered";
      } else if (e.code == 'invalid-email') {
        message = "❌ Invalid Gmail address";
      } else if (e.code == 'weak-password') {
        message = "❌ Password is too weak";
      } else if (e.code == 'network-request-failed') {
        message = "❌ Check your internet connection";
      } else {
        message = "❌ ${e.message ?? 'Account creation failed'}";
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
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    gmailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // ─────────────────────────────────────────────
  // BUILD SIGN UP PAGE
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 162, 174, 210),

      // APP BAR
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 86, 89, 99),
        elevation: 0,

        iconTheme: const IconThemeData(
          color: Colors.white,
        ),

        title: const Text(
          "Create Account",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      // BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),

        child: Form(
          key: formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ─────────────────────────────
              // USERNAME
              // ─────────────────────────────

              const Text(
                "Username",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: usernameController,

                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),

                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Enter username";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ─────────────────────────────
              // GMAIL
              // ─────────────────────────────

              const Text(
                "Gmail",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: gmailController,

                keyboardType: TextInputType.emailAddress,

                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),

                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Enter Gmail";
                  }

                  if (!v.trim().endsWith("@gmail.com")) {
                    return "Enter valid Gmail";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ─────────────────────────────
              // PHONE NUMBER
              // ─────────────────────────────

              const Text(
                "Phone Number",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: phoneController,

                keyboardType: TextInputType.phone,

                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),

                validator: (v) {
                  if (v == null || v.trim().length != 10) {
                    return "Phone number must be 10 digits";
                  }

                  if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) {
                    return "Enter only numbers";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ─────────────────────────────
              // PASSWORD
              // ─────────────────────────────

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
                    return "Password must be at least 6 characters";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ─────────────────────────────
              // CONFIRM PASSWORD
              // ─────────────────────────────

              const Text(
                "Confirm Password",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: confirmPasswordController,

                obscureText: !showConfirmPassword,

                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: const OutlineInputBorder(),

                  suffixIcon: IconButton(
                    icon: Icon(
                      showConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),

                    onPressed: () {
                      setState(() {
                        showConfirmPassword =
                            !showConfirmPassword;
                      });
                    },
                  ),
                ),

                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return "Confirm your password";
                  }

                  if (v != passwordController.text) {
                    return "Passwords do not match";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 30),

              // ─────────────────────────────
              // CREATE ACCOUNT BUTTON
              // ─────────────────────────────

              GestureDetector(
                onTap: isLoading ? null : createAccount,

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
                            "Create Account",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ─────────────────────────────
              // GO TO SIGN IN
              // ─────────────────────────────

              Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignInPage(),
                        ),
                      );
                    },

                    child: const Text(
                      "Sign In",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
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
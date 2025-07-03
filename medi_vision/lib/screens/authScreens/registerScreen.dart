import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../consts/themes.dart'; // Assuming this is where AppTheme, AppColors, etc. are defined

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _userType = 'Normal User';
  final List<String> _userTypes = ['Normal User', 'Doctor'];
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isEditMode = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkEditMode();
  }

  void _checkEditMode() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic> && args['editMode'] == true) {
      if (mounted) {
        setState(() {
          _isEditMode = true;
          _fullNameController.text = args['fullName']?.toString() ?? '';
          _emailController.text = args['email']?.toString() ?? '';
          _phoneController.text = args['phoneNumber']?.toString().replaceAll('PK +92 ', '') ?? '';
          _userType = args['userType']?.toString() ?? 'Normal User';
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> _showExitConfirmation() async {
    if (!_isEditMode &&
        (_fullNameController.text.isNotEmpty ||
            _emailController.text.isNotEmpty ||
            _phoneController.text.isNotEmpty)) {
      return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          ),
          title: Text('Discard Changes?', style: AppStyles.cardTitleStyle),
          content: Text(
            'You have unsaved changes. Are you sure you want to leave?',
            style: AppStyles.cardSubtitleStyle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: Theme.of(context).textTheme.bodyMedium),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Discard',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ) ??
          false;
    }
    return true;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userData = {
      'fullName': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phoneNumber': 'PK +92 ${_phoneController.text.trim()}',
      'userType': _userType,
      'createdAt': Timestamp.now(),
    };

    try {
      if (_isEditMode) {
        await Future.delayed(const Duration(seconds: 2)); // Simulate API call
        if (!mounted) return;
        Navigator.pop(context, userData);
      } else {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final userId = userCredential.user?.uid;
        if (userId != null) {
          final collection = _userType == 'Doctor' ? 'doctors' : 'users';
          await FirebaseFirestore.instance.collection(collection).doc(userId).set(userData);
        }

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard', arguments: userData);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMsg = 'An error occurred';
      if (e.code == 'email-already-in-use') {
        errorMsg = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        errorMsg = 'The password is too weak.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'The email address is invalid.';
      }
      _showErrorSnackbar(errorMsg);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppStyles.cardSubtitleStyle.copyWith(color: AppColors.textOnPrimary)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        margin: EdgeInsets.all(AppDimensions.paddingSmall),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _showExitConfirmation();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isEditMode ? 'Edit Profile' : 'Register'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _showExitConfirmation();
              if (shouldPop && context.mounted) Navigator.pop(context);
            },
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryLight,
                AppColors.background,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: Responsive.padding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Animated Profile Avatar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.card,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(
                        Icons.qr_code_scanner,
                        size: 55,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isEditMode ? 'Update Your Profile' : 'Create Your Account',
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill in the details below to ${_isEditMode ? 'update' : 'get started'}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person),
                              ),
                              style: theme.textTheme.bodyLarge,
                              validator: (value) =>
                              value == null || value.isEmpty ? 'Please enter your full name' : null,
                            ),
                            const SizedBox(height: AppDimensions.paddingMedium),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: Icon(Icons.email),
                              ),
                              style: theme.textTheme.bodyLarge,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter your email';
                                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppDimensions.paddingMedium),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimensions.paddingSmall,
                                    vertical: AppDimensions.paddingMedium,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
                                  ),
                                  child: Text(
                                    'PK +92',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.paddingSmall),
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Phone Number',
                                      prefixIcon: Icon(Icons.phone),
                                    ),
                                    style: theme.textTheme.bodyLarge,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Please enter your phone number';
                                      if (value.length < 10) return 'Phone number must be 10 digits';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.paddingMedium),
                            if (!_isEditMode) ...[
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                  ),
                                ),
                                style: theme.textTheme.bodyLarge,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter a password';
                                  if (value.length < 6) return 'Password must be at least 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppDimensions.paddingMedium),
                            ],
                            Text(
                              'Are you?',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppDimensions.paddingSmall),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _userType,
                                items: _userTypes.map((String type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type, style: theme.textTheme.bodyLarge),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() => _userType = newValue);
                                  }
                                },
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppDimensions.paddingMedium,
                                    vertical: AppDimensions.paddingSmall,
                                  ),
                                  border: InputBorder.none,
                                ),
                                icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                                dropdownColor: AppColors.card,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.paddingLarge),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
                                  ),
                                  elevation: _isLoading ? 0 : 4,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(AppColors.textOnPrimary),
                                  ),
                                )
                                    : Text(
                                  _isEditMode ? 'Save Changes' : 'Continue',
                                  style: AppStyles.buttonTextStyle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
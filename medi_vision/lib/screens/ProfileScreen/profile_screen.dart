import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../consts/bottomNavbar.dart';
import '../../consts/themes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 2;
  late Map<String, dynamic> _userData;
  bool _isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        Map<String, dynamic>? data;
        String collectionName = 'users';
        int retries = 3;
        int attempt = 0;

        while (attempt < retries && data == null) {
          // Check the "users" collection first
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            data = userDoc.data() as Map<String, dynamic>;
          } else {
            // If not found in "users", check "doctors"
            userDoc = await FirebaseFirestore.instance
                .collection('doctors')
                .doc(user.uid)
                .get();
            if (userDoc.exists) {
              data = userDoc.data() as Map<String, dynamic>;
              collectionName = 'doctors';
            }
          }

          if (data == null && attempt < retries - 1) {
            // Wait before retrying
            await Future.delayed(const Duration(seconds: 1));
          }
          attempt++;
        }

        if (data != null) {
          setState(() {
            _userData = {
              'fullName': data!['fullName'] ?? 'No name',
              'email': data['email'] ?? 'No email',
              'phoneNumber': data['phoneNumber'] ?? 'Not provided',
              'userType': data['userType'] ?? 'User',
              'uid': user.uid,
              'collection': collectionName,
            };
            _isLoading = false;
          });
        } else {
          throw Exception('User data not found in Firestore after $retries attempts');
        }
      } else {
        throw Exception('No user logged in');
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching user data: $e\n$stackTrace');
      setState(() {
        _userData = _defaultUserData();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch user data: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _defaultUserData() => {
    'fullName': 'Guest User',
    'email': 'No email',
    'phoneNumber': 'Not provided',
    'userType': 'User',
    'uid': null,
    'collection': 'users',
  };

  Future<void> _updateUserData(Map<String, dynamic> newData) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Validate required fields
      if (newData['fullName'] == null || newData['fullName'].isEmpty) {
        throw 'Full name is required';
      }
      if (newData['phoneNumber'] == null || newData['phoneNumber'].isEmpty) {
        throw 'Phone number is required';
      }
      if (newData['userType'] == null || newData['userType'].isEmpty) {
        throw 'User type is required';
      }

      // Prepare update data
      final updateData = {
        'fullName': newData['fullName'] as String,
        'phoneNumber': newData['phoneNumber'] as String,
        'userType': newData['userType'] as String,
        'updatedAt': Timestamp.now(),
      };

      // Email must not be changed
      if (newData.containsKey('email')) {
        if (newData['email'] != user.email) {
          throw 'Email cannot be changed';
        }
      }

      // Update display name
      await user.updateDisplayName(newData['fullName']);

      // Update Firestore
      final collectionName = _userData['collection'] ?? 'users';
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(user.uid)
          .update(updateData);

      await _fetchUserData();

    } on FirebaseAuthException catch (e) {
      debugPrint('Error updating user data: $e');
      throw _getFriendlyErrorMessage(e);
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }


  String _getFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'requires-recent-login':
        return 'Please reauthenticate to update your email';
      case 'email-already-in-use':
        return 'This email is already in use by another account';
      case 'invalid-email':
        return 'Please enter a valid email address';
      default:
        return e.message ?? 'An error occurred';
    }
  }

  void _onNavBarTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    final routes = {
      0: '/dashboard',
      1: '/scandocscreen',
      2: '/profile',
    };

    if (routes.containsKey(index)) {
      Navigator.pushReplacementNamed(
        context,
        routes[index]!,
      ).catchError((error) {
        debugPrint('Navigation error: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigation failed: ${error.toString()}')),
          );
        }
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/authOption',
            (Route<dynamic> route) => false,
      );
    } catch (e, stackTrace) {
      debugPrint('Logout error: $e\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      bottomNavigationBar: AnimatedNavBar(
        onTap: _onNavBarTapped,
        currentIndex: _selectedIndex,
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Profile",
          style: textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          buildProfilePopupMenu(
            context,
            onEdit: (ctx, args) => editProfile(
              ctx,
              args,
              onSave: _updateUserData,
              allowEmailEdit: false,
            ),
            onLogout: _logout,
            editArgs: {
              'editMode': true,
              ..._userData,
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.8),
              colorScheme.primary.withOpacity(0.4),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge, vertical: 16),
            child: Column(
              children: [
                buildProfileAvatar(context),
                const SizedBox(height: 16),
                buildUserName(_userData['fullName'], context),
                const SizedBox(height: 8),
                buildUserTypeBadge(_userData['userType'], context),
                const SizedBox(height: 32),
                buildProfileInfoCard(
                  _userData['email'],
                  _userData['phoneNumber'],
                  context,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper Methods
Future<void> editProfile(
    BuildContext context,
    Map<String, dynamic> args, {
      required Future<void> Function(Map<String, dynamic>) onSave,
      required bool allowEmailEdit,
    }) async {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  final nameController = TextEditingController(text: args['fullName']);
  final emailController = TextEditingController(text: args['email']);
  final phoneController = TextEditingController(text: args['phoneNumber']);
  String userType = args['userType'];

  final formKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      title: Text(
        'Edit Profile',
        style: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  enabled: false,

                  labelText: 'Email',
                  labelStyle: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                enabled: allowEmailEdit,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Email is required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Allow only digits
                  LengthLimitingTextInputFormatter(10), // Limit to 10 digits
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Phone is required';
                  if (value.length != 10) return 'Phone number must be 10 digits';
                  return null;
                },
              ),
              if (args.containsKey('userType')) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: userType,
                  items: ['Normal User', 'Doctor']
                      .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(
                      type,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ))
                      .toList(),
                  onChanged: (value) => userType = value!,
                  decoration: InputDecoration(
                    labelText: 'User Type',
                    labelStyle: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
            ),
          ),
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              try {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );

                // Prepare the data to save
                final newData = {
                  'fullName': nameController.text,
                  'phoneNumber': phoneController.text,
                  if (args.containsKey('userType')) 'userType': userType,
                };

                // Only include email if it's editable and different from current
                if (allowEmailEdit && emailController.text != args['email']) {
                  newData['email'] = emailController.text;
                }

                await onSave(newData);

                // Close both dialogs
                Navigator.pop(context); // Close loading dialog
                Navigator.pop(context); // Close edit dialog

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Profile updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } on FirebaseAuthException catch (e) {
                Navigator.pop(context); // Close loading dialog if still open
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_getErrorMessage(e)),
                    backgroundColor: colorScheme.error,
                  ),
                );
              } catch (e) {
                Navigator.pop(context); // Close loading dialog if still open
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update: $e'),
                    backgroundColor: colorScheme.error,
                  ),
                );
              }
            }
          },
          child: Text(
            'Save',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

String _getErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'requires-recent-login':
      return 'Please reauthenticate to update your email';
    case 'email-already-in-use':
      return 'This email is already in use';
    case 'invalid-email':
      return 'Please enter a valid email';
    case 'operation-not-allowed':
      return 'Email/password accounts are not enabled';
    default:
      return e.message ?? 'An error occurred';
  }
}

void showLogoutDialog(
    BuildContext context,
    VoidCallback onConfirm,
    ) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        title: Text(
          'Confirm Logout',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              'Logout',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onError,
              ),
            ),
          ),
        ],
      );
    },
  );
}

PopupMenuItem<String> buildMenuItem(
    BuildContext context, {
      required IconData icon,
      required String label,
      required String value,
      bool isDestructive = false,
    }) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  return PopupMenuItem<String>(
    value: value,
    height: 40,
    child: Row(
      children: [
        Icon(
          icon,
          color: isDestructive ? colorScheme.error : colorScheme.primary,
          size: 22,
        ),
        const SizedBox(width: AppDimensions.paddingSmall),
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: isDestructive ? colorScheme.error : colorScheme.onSurface,
          ),
        ),
      ],
    ),
  );
}

// Component Widgets
Widget buildProfileAvatar(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return Container(
    margin: const EdgeInsets.only(top: 30, bottom: 20),
    child: Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary.withOpacity(0.1),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                offset: const Offset(-4, -4),
                blurRadius: 8,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(4, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.transparent,
            child: Icon(
              Icons.person,
              size: 60,
              color: colorScheme.primary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.camera_alt,
            size: 16,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

Widget buildUserName(String fullName, BuildContext context) {
  return Text(
    fullName.isNotEmpty ? fullName : 'No Name Provided',
    style: Theme.of(context).textTheme.displayLarge?.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.bold,
    ),
    textAlign: TextAlign.center,
  );
}

Widget buildUserTypeBadge(String userType, BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: colorScheme.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: colorScheme.primary, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      userType.toUpperCase(),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
  );
}

Widget buildProfileInfoCard(String email, String phoneNumber, BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildProfileInfoItem('Email', email, Icons.email_outlined, context),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildProfileInfoItem('Phone', phoneNumber, Icons.phone_outlined, context),
        ],
      ),
    ),
  );
}

Widget buildProfilePopupMenu(
    BuildContext context, {
      required Function(BuildContext, Map<String, dynamic>) onEdit,
      required Function() onLogout,
      required Map<String, dynamic> editArgs,
    }) {
  final colorScheme = Theme.of(context).colorScheme;
  return PopupMenuButton<String>(
    icon: Icon(
      Icons.more_vert,
      color: Colors.white,
      size: 28,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
      side: BorderSide(color: colorScheme.primary.withOpacity(0.2), width: 1),
    ),
    elevation: 4,
    color: colorScheme.surface,
    onSelected: (value) {
      if (value == 'edit') {
        onEdit(context, editArgs);
      } else if (value == 'logout') {
        showLogoutDialog(context, onLogout);
      }
    },
    itemBuilder: (BuildContext context) {
      return [
        buildMenuItem(
          context,
          icon: Icons.edit,
          label: 'Edit Profile',
          value: 'edit',
        ),
        buildMenuItem(
          context,
          icon: Icons.logout,
          label: 'Logout',
          value: 'logout',
          isDestructive: true,
        ),
      ];
    },
  );
}

Widget _buildProfileInfoItem(String label, String value, IconData icon, BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final displayValue = value.isEmpty ? 'Not provided' : value;
  final textColor = value.isEmpty ? Colors.grey[600] : AppColors.textPrimary;

  return Padding(
    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorScheme.primary, size: AppDimensions.iconSizeSmall),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayValue,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

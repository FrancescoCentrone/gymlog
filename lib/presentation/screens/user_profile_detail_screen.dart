import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/models/user_profile.dart';
import 'package:gym_log/presentation/state/user_profile_provider.dart';
import 'package:intl/intl.dart';

class UserProfileDetailScreen extends ConsumerStatefulWidget {
  const UserProfileDetailScreen({super.key});

  @override
  ConsumerState<UserProfileDetailScreen> createState() => _UserProfileDetailScreenState();
}

class _UserProfileDetailScreenState extends ConsumerState<UserProfileDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _heightController = TextEditingController();
  
  String _selectedSex = 'M';
  DateTime? _dateOfBirth;
  bool _isEditing = false;
  UserProfile? _currentProfile;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _loadProfileData(UserProfile profile) {
    _nameController.text = profile.name;
    _surnameController.text = profile.surname;
    _emailController.text = profile.email;
    _heightController.text = profile.height.toString();
    _selectedSex = profile.sex;
    _dateOfBirth = profile.dateOfBirth;
    _currentProfile = profile;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_dateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your date of birth'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final profile = UserProfile(
        id: _currentProfile?.id,
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        email: _emailController.text.trim(),
        sex: _selectedSex,
        dateOfBirth: _dateOfBirth!,
        height: double.parse(_heightController.text.trim()),
      );

      await ref.read(userProfileProvider.notifier).saveUserProfile(profile);

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: profileAsync.when(
          data: (profile) {
            if (profile != null && !_isEditing) {
              return [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      _loadProfileData(profile);
                    });
                  },
                ),
              ];
            }
            return [];
          },
          loading: () => [],
          error: (_, stack) => [],
        ),
      ),
      body: profileAsync.when(
        data: (profile) {
          // First time or editing mode
          if (profile == null || _isEditing) {
            if (profile != null && _currentProfile == null) {
              // Load data when entering edit mode
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadProfileData(profile);
              });
            }
            
            return _buildEditForm();
          }
          
          // Display mode
          return _buildDisplayMode(profile);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _surnameController,
              decoration: const InputDecoration(
                labelText: 'Surname',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your surname';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSex,
              decoration: const InputDecoration(
                labelText: 'Sex',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wc),
              ),
              items: const [
                DropdownMenuItem(value: 'M', child: Text('Male')),
                DropdownMenuItem(value: 'F', child: Text('Female')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSex = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _dateOfBirth != null
                      ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
                      : 'Select date',
                  style: TextStyle(
                    color: _dateOfBirth != null ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.height),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your height';
                }
                final height = double.tryParse(value);
                if (height == null || height <= 0) {
                  return 'Please enter a valid height';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Save Profile',
                style: TextStyle(fontSize: 16),
              ),
            ),
            if (_currentProfile != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _currentProfile = null;
                  });
                },
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayMode(UserProfile profile) {
    final age = DateTime.now().year - profile.dateOfBirth.year;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(Icons.person, 'Name', profile.name),
                  const Divider(),
                  _buildInfoRow(Icons.person_outline, 'Surname', profile.surname),
                  const Divider(),
                  _buildInfoRow(Icons.email, 'Email', profile.email),
                  const Divider(),
                  _buildInfoRow(
                    Icons.wc,
                    'Sex',
                    profile.sex == 'M' ? 'Male' : 'Female',
                  ),
                  const Divider(),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Date of Birth',
                    '${DateFormat('dd/MM/yyyy').format(profile.dateOfBirth)} ($age years old)',
                  ),
                  const Divider(),
                  _buildInfoRow(
                    Icons.height,
                    'Height',
                    '${profile.height.toStringAsFixed(0)} cm',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isEditing = true;
                _loadProfileData(profile);
              });
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

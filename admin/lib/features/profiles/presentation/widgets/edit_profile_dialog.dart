import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/profile_edit_input.dart';
import '../../data/profile_form_options.dart';
import '../../data/profiles_repository.dart';
import '../providers/profiles_providers.dart';
import 'searchable_picker_dialog.dart';
import 'searchable_value_field.dart';

/// Loads `profiles/{profileId}` from Firestore and saves edits back.
class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({super.key, required this.profileId});

  final String profileId;

  static Future<bool?> show(BuildContext context, String profileId) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => EditProfileDialog(profileId: profileId),
    );
  }

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _originalId;
  late final TextEditingController _first;
  late final TextEditingController _middle;
  late final TextEditingController _last;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  DateTime? _birthDate;
  late String _gender;
  late String _type;
  late int _heightFeet;
  late int _heightInches;
  bool _active = true;
  bool _isVerified = false;

  String? _branch;
  String? _education;
  String? _job;

  List<String> _branchOptions = const [];

  static const _genders = ['male', 'female'];
  static const _types = ['First Marriage', 'Remarriage'];
  static const _feetOptions = [4, 5, 6, 7];
  static const _inchOptions = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

  @override
  void initState() {
    super.initState();
    _originalId = TextEditingController();
    _first = TextEditingController();
    _middle = TextEditingController();
    _last = TextEditingController();
    _gender = _genders.first;
    _type = _types.first;
    _heightFeet = 5;
    _heightInches = 0;
    _loadProfile();
  }

  @override
  void dispose() {
    _originalId.dispose();
    _first.dispose();
    _middle.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final repo = ref.read(profilesRepositoryProvider);
      await repo.ensureFormOptionsLoaded();
      final data = await repo.fetchProfileDocument(widget.profileId);
      final cache = repo.formOptionsCache;

      if (!mounted) return;

      _originalId.text = data['original_id']?.toString() ?? '';
      _first.text = data['first_name']?.toString() ?? '';
      _middle.text = data['middle_name']?.toString() ?? '';
      _last.text = data['last_name']?.toString() ?? '';

      _gender = ProfilesRepository.normalizeGender(data['gender']);
      _type = ProfilesRepository.normalizeMarriageType(data['type']);

      final height = ProfilesRepository.parseHeight(data);
      _heightFeet = height.feet;
      _heightInches = height.inches;

      _branch = data['branch']?.toString();
      _education = data['education']?.toString();
      _job = data['job']?.toString();

      var branches = ProfileFormOptions.withCurrentValue(
        _branch,
        cache.branchOptions,
      );

      if (branches.isNotEmpty && (_branch == null || !branches.contains(_branch))) {
        _branch ??= branches.first;
      }

      _birthDate = ProfilesRepository.parseBirthDate(data['birth_date']);
      _active = data['active'] == true;
      _isVerified = data['is_verified'] == true;

      setState(() {
        _branchOptions = branches;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _pickEducation() async {
    final groups =
        ref.read(profilesRepositoryProvider).formOptionsCache.educationGroups;
    final picked = await SearchablePickerDialog.show(
      context,
      title: 'Select education',
      groups: groups,
      currentValue: _education,
    );
    if (picked != null && mounted) setState(() => _education = picked);
  }

  Future<void> _pickOccupation() async {
    final groups =
        ref.read(profilesRepositoryProvider).formOptionsCache.occupationGroups;
    final picked = await SearchablePickerDialog.show(
      context,
      title: 'Select occupation',
      groups: groups,
      currentValue: _job,
    );
    if (picked != null && mounted) setState(() => _job = picked);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await ref.read(profilesRepositoryProvider).updateProfile(
            profileId: widget.profileId,
            input: ProfileEditInput(
              firstName: _first.text,
              middleName: _middle.text,
              lastName: _last.text,
              originalId: _originalId.text,
              gender: _gender,
              type: _type,
              branch: _branch,
              education: _education,
              job: _job,
              heightFeet: _heightFeet,
              heightInches: _heightInches,
              birthDate: _birthDate,
              active: _active,
              isVerified: _isVerified,
            ),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  String _birthDateLabel() {
    if (_birthDate == null) return 'Not set';
    final d = _birthDate!.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String _genderLabel(String g) =>
      g == 'male' ? 'Male' : 'Female';

  static String _inchLabel(int i) => i == 0 ? '0"' : '$i"';

  static String _dropdownItemLabel<T>(DropdownMenuItem<T> item) {
    final child = item.child;
    if (child is Text) {
      return child.data ?? item.value?.toString() ?? '';
    }
    return item.value?.toString() ?? '';
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      selectedItemBuilder: (context) {
        return items.map((item) {
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              _dropdownItemLabel(item),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      items: items,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profile'),
      content: SizedBox(
        width: 560,
        child: _loading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : _loadError != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!,
                          style: const TextStyle(color: AppTheme.errorColor)),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: _loadProfile, child: const Text('Retry')),
                    ],
                  )
                : SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SelectableText(
                            'ID: ${widget.profileId}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _originalId,
                            decoration: const InputDecoration(
                              labelText: 'Book ID (original_id)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _first,
                                  decoration: const InputDecoration(
                                    labelText: 'First name *',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _middle,
                                  decoration: const InputDecoration(
                                    labelText: 'Middle name',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _last,
                                  decoration: const InputDecoration(
                                    labelText: 'Last name',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _dropdown<String>(
                                  label: 'Gender',
                                  value: _gender,
                                  items: [
                                    for (final g in _genders)
                                      DropdownMenuItem(
                                        value: g,
                                        child: Text(_genderLabel(g)),
                                      ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setState(() => _gender = v);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _dropdown<String>(
                                  label: 'Type of marriage',
                                  value: _type,
                                  items: [
                                    for (final t in _types)
                                      DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setState(() => _type = v);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_branchOptions.isNotEmpty)
                            _dropdown<String>(
                              label: 'Branch',
                              value: _branch != null &&
                                      _branchOptions.contains(_branch)
                                  ? _branch!
                                  : _branchOptions.first,
                              items: [
                                for (final b in _branchOptions)
                                  DropdownMenuItem(value: b, child: Text(b)),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _branch = v);
                              },
                            )
                          else
                            const Text(
                              'No branch options in app_config/subcaste_options',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          const SizedBox(height: 12),
                          SearchableValueField(
                            label: 'Education',
                            value: _education,
                            onTap: _pickEducation,
                          ),
                          const SizedBox(height: 12),
                          SearchableValueField(
                            label: 'Occupation',
                            value: _job,
                            onTap: _pickOccupation,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Height',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _dropdown<int>(
                                  label: 'Feet',
                                  value: _heightFeet,
                                  items: [
                                    for (final f in _feetOptions)
                                      DropdownMenuItem(
                                        value: f,
                                        child: Text('$f ft'),
                                      ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _heightFeet = v);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _dropdown<int>(
                                  label: 'Inches',
                                  value: _heightInches,
                                  items: [
                                    for (final i in _inchOptions)
                                      DropdownMenuItem(
                                        value: i,
                                        child: Text(_inchLabel(i)),
                                      ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _heightInches = v);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _pickBirthDate,
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text('DOB: ${_birthDateLabel()}'),
                          ),
                          if (_birthDate != null)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => setState(() => _birthDate = null),
                                child: const Text('Clear DOB'),
                              ),
                            ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Active'),
                            value: _active,
                            onChanged: (v) => setState(() => _active = v),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Verified'),
                            value: _isVerified,
                            onChanged: (v) => setState(() => _isVerified = v),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (!_loading && _loadError == null)
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          ),
      ],
    );
  }
}

/// Fields the admin panel may update on `profiles/{id}`.
class ProfileEditInput {
  const ProfileEditInput({
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.originalId,
    required this.gender,
    required this.type,
    this.branch,
    this.education,
    this.job,
    required this.heightFeet,
    required this.heightInches,
    this.birthDate,
    required this.active,
    required this.isVerified,
  });

  final String firstName;
  final String? middleName;
  final String lastName;
  final String? originalId;
  final String gender;
  final String type;
  final String? branch;
  final String? education;
  final String? job;
  final int heightFeet;
  final int heightInches;
  final DateTime? birthDate;
  final bool active;
  final bool isVerified;
}

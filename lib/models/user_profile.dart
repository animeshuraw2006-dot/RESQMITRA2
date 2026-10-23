class UserProfile {
  UserProfile({required this.role, this.fields = const {}});

  final String role;
  final Map<String, dynamic> fields;

  Map<String, dynamic> toJson() => {'role': role, 'fields': fields};

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        role: json['role'] as String? ?? 'helpSeeker',
        fields: Map<String, dynamic>.from(json['fields'] as Map? ?? {}),
      );
}

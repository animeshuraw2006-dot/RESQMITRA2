class ResponderModel {
  const ResponderModel({required this.uid, required this.active, required this.verified, this.skills = const []});
  final String uid;
  final bool active;
  final bool verified;
  final List<String> skills;

  factory ResponderModel.fromJson(String uid, Map<String, dynamic> json) => ResponderModel(
    uid: uid,
    active: json['active'] == true,
    verified: json['verified'] == true,
    skills: (json['skills'] as List<dynamic>? ?? const []).whereType<String>().toList(growable: false),
  );
}

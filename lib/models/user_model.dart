class UserModel {
  const UserModel({required this.uid, required this.email, this.displayName, this.isResponder = false});
  final String uid;
  final String email;
  final String? displayName;
  final bool isResponder;

  Map<String, dynamic> toJson() => {
    'uid': uid, 'email': email, 'displayName': displayName, 'isResponder': isResponder,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['uid'] as String,
    email: json['email'] as String? ?? '',
    displayName: json['displayName'] as String?,
    // Client JSON never grants trusted responder privileges.
    isResponder: false,
  );
}

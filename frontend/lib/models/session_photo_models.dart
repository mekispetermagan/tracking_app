class SessionPhoto {
  final int id;
  final int sessionLogId;
  final int mentorProfileId;
  final int photoNumber;
  final String url;
  final DateTime uploadedAt;

  const SessionPhoto({
    required this.id,
    required this.sessionLogId,
    required this.mentorProfileId,
    required this.photoNumber,
    required this.url,
    required this.uploadedAt,
  });

  factory SessionPhoto.fromJson(Map<String, dynamic> json) {
    return SessionPhoto(
      id: json['id'] as int,
      sessionLogId: json['session_log_id'] as int,
      mentorProfileId: json['mentor_profile_id'] as int,
      photoNumber: json['photo_number'] as int,
      url: json['url'] as String,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }
}

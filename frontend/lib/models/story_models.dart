class StoryPhoto {
  final int id;
  final String url;
  final DateTime uploadedAt;

  const StoryPhoto({
    required this.id,
    required this.url,
    required this.uploadedAt,
  });

  factory StoryPhoto.fromJson(Map<String, dynamic> json) {
    return StoryPhoto(
      id: json['id'] as int,
      url: json['url'] as String,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }
}

class Story {
  final int id;
  final String text;

  final int courseId;
  final String courseName;

  final int submittedByMentorProfileId;
  final String submitterFirstName;
  final String submitterLastName;

  final DateTime submissionMonth;
  final StoryPhoto photo;

  final bool isWinner;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Story({
    required this.id,
    required this.text,
    required this.courseId,
    required this.courseName,
    required this.submittedByMentorProfileId,
    required this.submitterFirstName,
    required this.submitterLastName,
    required this.submissionMonth,
    required this.photo,
    required this.isWinner,
    required this.createdAt,
    required this.updatedAt,
  });

  String get submitterName {
    return '$submitterFirstName $submitterLastName';
  }

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as int,
      text: json['text'] as String,
      courseId: json['course_id'] as int,
      courseName: json['course_name'] as String,
      submittedByMentorProfileId: json['submitted_by_mentor_profile_id'] as int,
      submitterFirstName: json['submitter_first_name'] as String,
      submitterLastName: json['submitter_last_name'] as String,
      submissionMonth: DateTime.parse(json['submission_month'] as String),
      photo: StoryPhoto.fromJson(json['photo'] as Map<String, dynamic>),
      isWinner: json['is_winner'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class MentorStory extends Story {
  final int? myRating;
  final bool canRate;

  const MentorStory({
    required super.id,
    required super.text,
    required super.courseId,
    required super.courseName,
    required super.submittedByMentorProfileId,
    required super.submitterFirstName,
    required super.submitterLastName,
    required super.submissionMonth,
    required super.photo,
    required super.isWinner,
    required super.createdAt,
    required super.updatedAt,
    required this.myRating,
    required this.canRate,
  });

  factory MentorStory.fromJson(Map<String, dynamic> json) {
    final story = Story.fromJson(json);

    return MentorStory(
      id: story.id,
      text: story.text,
      courseId: story.courseId,
      courseName: story.courseName,
      submittedByMentorProfileId: story.submittedByMentorProfileId,
      submitterFirstName: story.submitterFirstName,
      submitterLastName: story.submitterLastName,
      submissionMonth: story.submissionMonth,
      photo: story.photo,
      isWinner: story.isWinner,
      createdAt: story.createdAt,
      updatedAt: story.updatedAt,
      myRating: json['my_rating'] as int?,
      canRate: json['can_rate'] as bool,
    );
  }
}

class AdminStory extends Story {
  final bool active;
  final int ratingCount;
  final double? averageRating;

  const AdminStory({
    required super.id,
    required super.text,
    required super.courseId,
    required super.courseName,
    required super.submittedByMentorProfileId,
    required super.submitterFirstName,
    required super.submitterLastName,
    required super.submissionMonth,
    required super.photo,
    required super.isWinner,
    required super.createdAt,
    required super.updatedAt,
    required this.active,
    required this.ratingCount,
    required this.averageRating,
  });

  factory AdminStory.fromJson(Map<String, dynamic> json) {
    final story = Story.fromJson(json);

    return AdminStory(
      id: story.id,
      text: story.text,
      courseId: story.courseId,
      courseName: story.courseName,
      submittedByMentorProfileId: story.submittedByMentorProfileId,
      submitterFirstName: story.submitterFirstName,
      submitterLastName: story.submitterLastName,
      submissionMonth: story.submissionMonth,
      photo: story.photo,
      isWinner: story.isWinner,
      createdAt: story.createdAt,
      updatedAt: story.updatedAt,
      active: json['active'] as bool,
      ratingCount: json['rating_count'] as int,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
    );
  }
}

class StoryWinner {
  final DateTime month;
  final DateTime selectedAt;
  final Story story;

  const StoryWinner({
    required this.month,
    required this.selectedAt,
    required this.story,
  });

  factory StoryWinner.fromJson(Map<String, dynamic> json) {
    return StoryWinner(
      month: DateTime.parse(json['month'] as String),
      selectedAt: DateTime.parse(json['selected_at'] as String),
      story: Story.fromJson(json['story'] as Map<String, dynamic>),
    );
  }
}

class StoryCreateRequest {
  final int courseId;
  final String text;
  final String photoPath;

  const StoryCreateRequest({
    required this.courseId,
    required this.text,
    required this.photoPath,
  });

  Map<String, String> toFields() {
    return {'course_id': courseId.toString(), 'text': text};
  }
}

class StoryUpdateRequest {
  final String text;

  const StoryUpdateRequest({required this.text});

  Map<String, dynamic> toJson() {
    return {'text': text};
  }
}

class StoryRatingRequest {
  final int rating;

  const StoryRatingRequest({required this.rating});

  Map<String, dynamic> toJson() {
    return {'rating': rating};
  }
}

class StoryWinnerRequest {
  final int storyId;

  const StoryWinnerRequest({required this.storyId});

  Map<String, dynamic> toJson() {
    return {'story_id': storyId};
  }
}

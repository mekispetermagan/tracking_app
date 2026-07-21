Map<String, dynamic> courseJson({
  int id = 8,
  String name = 'Robotics',
  bool active = true,
  List<int> mentorIds = const [5],
  List<int> studentIds = const [7],
}) => {
  'id': id,
  'name': name,
  'description': 'Build robots',
  'country_id': 2,
  'day_of_week': 6,
  'start_time': '09:30',
  'active': active,
  'mentor_ids': mentorIds,
  'student_ids': studentIds,
};

Map<String, dynamic> mentorJson({
  int id = 5,
  String firstName = 'Grace',
  bool active = true,
  List<int> courseIds = const [8],
}) => {
  'id': id,
  'account_id': id + 10,
  'first_name': firstName,
  'last_name': 'Hopper',
  'phone': '070000000$id',
  'country_id': 2,
  'preferred_language': 'eng',
  'active': active,
  'course_ids': courseIds,
};

Map<String, dynamic> studentJson({
  int id = 7,
  String firstName = 'Ada',
  bool active = true,
  List<int> courseIds = const [8],
}) => {
  'id': id,
  'first_name': firstName,
  'last_name': 'Lovelace',
  'origin_country_id': 2,
  'birth_year': 2012,
  'gender': 'female',
  'active': active,
  'course_ids': courseIds,
};

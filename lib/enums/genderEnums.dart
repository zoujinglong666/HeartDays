// 性别选项
enum Gender {
  secret(0, '保密'),
  male(1, '男'),
  female(2, '女');

  const Gender(this.value, this.label);

  final int value;
  final String label;

  static Gender fromValue(int value) {
    return Gender.values.firstWhere(
      (gender) => gender.value == value,
      orElse: () => Gender.secret,
    );
  }

  static List<Map<String, dynamic>> get options {
    return Gender.values
        .map((gender) => {'value': gender.value, 'label': gender.label})
        .toList();
  }
}

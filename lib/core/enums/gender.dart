/// User biological gender for BMR calculation.
enum Gender {
  male(label: 'Male'),
  female(label: 'Female'),
  other(label: 'Other');

  const Gender({required this.label});

  final String label;
}

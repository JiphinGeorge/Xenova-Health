enum CoachTone {
  supportive(label: 'Supportive'),
  motivational(label: 'Motivational'),
  analytical(label: 'Analytical'),
  strict(label: 'Strict');

  const CoachTone({required this.label});
  final String label;
}

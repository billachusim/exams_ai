class Subject {
  final String slug;
  final String name;
  const Subject(this.slug, this.name);
}

const subjects = <Subject>[
  Subject('english', 'Use of English'),
  Subject('mathematics', 'Mathematics'),
  Subject('physics', 'Physics'),
  Subject('chemistry', 'Chemistry'),
  Subject('biology', 'Biology'),
  Subject('government', 'Government'),
  Subject('economics', 'Economics'),
  Subject('literature', 'Literature'),
  Subject('commerce', 'Commerce'),
  Subject('crs', 'CRS'),
  Subject('irs', 'IRS'),
  Subject('geography', 'Geography'),
  Subject('accounting', 'Accounts'),
  Subject('agric', 'Agric Science'),
];

String subjectName(String slug) =>
    subjects.firstWhere((s) => s.slug == slug, orElse: () => Subject(slug, slug)).name;

const exams = ['JAMB', 'WAEC', 'NECO'];

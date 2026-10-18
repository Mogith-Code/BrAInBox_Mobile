/// Which illustration a welcome slide shows.
enum WelcomeIllustration { cell, feedback, path }

/// One page of the welcome carousel. The text comes straight from Figma.
class WelcomeSlide {
  const WelcomeSlide({
    required this.title,
    required this.body,
    required this.illustration,
  });

  final String title;
  final String body;
  final WelcomeIllustration illustration;

  static const all = [
    WelcomeSlide(
      title: 'Learn smarter',
      body: 'AI notes, short notes and diagrams for every syllabus topic.',
      illustration: WelcomeIllustration.cell,
    ),
    WelcomeSlide(
      title: 'Know exactly what went wrong',
      body: 'AI checks your answers and finds your mistakes.',
      illustration: WelcomeIllustration.feedback,
    ),
    WelcomeSlide(
      title: "Always know what's next",
      body: 'Personalised next steps to improve, every single day.',
      illustration: WelcomeIllustration.path,
    ),
  ];
}

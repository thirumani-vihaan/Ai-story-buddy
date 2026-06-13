/// The story snippet Buddy narrates. This is the exact text from the brief,
/// with one gentle, child-friendly continuation for a warmer read-aloud.
class StoryContent {
  StoryContent._();

  static const String title = 'Pip and the Whispering Woods';

  static const List<String> paragraphs = [
    'Once upon a time, a clever little robot named Pip lost his shiny blue '
        'gear in the Whispering Woods...',
    "The blue gear was Pip's very favourite. It spun right in the middle of "
        'his chest and glowed a soft, happy blue whenever he felt curious.',
    'Pip tiptoed past tall mushrooms and humming fireflies, asking everyone he '
        'met, "Have you seen my shiny blue gear?"',
    'A wise old owl blinked twice and hooted, "Follow the things that sparkle, '
        'little robot." So Pip followed the twinkles deeper into the trees.',
    "There, tangled in a silver spider's web, something glittered blue. It was "
        'his gear! Gently, oh so gently, Pip set it free and popped it back '
        'into place.',
    'Click! His chest glowed bright blue again, and Pip laughed all the way '
        'home, already dreaming up his next big adventure.',
  ];

  /// The whole snippet as one block, used for text-to-speech *and* on-screen
  /// display, so the read-aloud highlight offsets line up with the text.
  static String get narration => paragraphs.join('\n\n');
}

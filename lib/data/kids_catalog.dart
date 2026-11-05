import 'package:flutter/material.dart';

/// One picture-card word in the kids plan.
class KidsWord {
  const KidsWord({
    required this.emoji,
    required this.word,
    required this.bangla,
    required this.sentence,
  });

  final String emoji;
  final String word;
  final String bangla;
  final String sentence;
}

/// A short sentence pattern the child repeats with the parent.
class KidsPhrase {
  const KidsPhrase({required this.text, required this.bangla});

  final String text;
  final String bangla;
}

/// One week of the 8-week school-starter plan.
class KidsWeek {
  const KidsWeek({
    required this.number,
    required this.title,
    required this.banglaTitle,
    required this.focus,
    required this.parentTip,
    required this.words,
    required this.phrases,
    required this.colors,
  });

  final int number;
  final String title;
  final String banglaTitle;
  final String focus;
  final String parentTip;
  final List<KidsWord> words;
  final List<KidsPhrase> phrases;
  final List<Color> colors;

  int get cardCount => words.length + phrases.length;
  int get wordCount => words.length;
}

class KidsCatalog {
  KidsCatalog._();

  static const weeks = <KidsWeek>[
    KidsWeek(
      number: 1,
      title: 'Hello & My Name',
      banglaTitle: 'হ্যালো ও আমার নাম',
      focus: 'Greetings, own name, teacher & friend',
      parentTip:
          'প্রথম সপ্তাহে শুধু ৩টি শব্দ দিয়ে শুরু করুন। প্রতিটি শব্দের সাথে হাত নেড়ে বা হাসিমুখে বলুন — এতে শিশু অনুকরণ করবে।',
      colors: [Color(0xFF34D399), Color(0xFF059669)],
      words: [
        KidsWord(
          emoji: '👋',
          word: 'hello',
          bangla: 'হ্যালো',
          sentence: 'Hello!',
        ),
        KidsWord(
          emoji: '🌅',
          word: 'good morning',
          bangla: 'শুভ সকাল',
          sentence: 'Good morning!',
        ),
        KidsWord(
          emoji: '🙋',
          word: 'my name',
          bangla: 'আমার নাম',
          sentence: 'My name is Riya.',
        ),
        KidsWord(
          emoji: '🧑‍🏫',
          word: 'teacher',
          bangla: 'শিক্ষক',
          sentence: 'This is my teacher.',
        ),
        KidsWord(
          emoji: '🧒',
          word: 'friend',
          bangla: 'বন্ধু',
          sentence: 'You are my friend.',
        ),
        KidsWord(
          emoji: '👋',
          word: 'bye',
          bangla: 'বিদায়',
          sentence: 'Bye-bye!',
        ),
      ],
      phrases: [
        KidsPhrase(
          text: 'Hello! My name is ...',
          bangla: 'হ্যালো! আমার নাম ...',
        ),
        KidsPhrase(
          text: 'Good morning, teacher.',
          bangla: 'শুভ সকাল, শিক্ষক।',
        ),
        KidsPhrase(
          text: 'You are my friend.',
          bangla: 'তুমি আমার বন্ধু।',
        ),
      ],
    ),
    KidsWeek(
      number: 2,
      title: 'My Things',
      banglaTitle: 'আমার জিনিসপত্র',
      focus: 'This is my..., where is...?',
      parentTip:
          'ঘরের আসল জিনিস দেখিয়ে বলুন — ব্যাগ, কাপ, বই। শব্দের সাথে বস্তু মিলিয়ে দিলে দ্রুত মনে থাকে।',
      colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
      words: [
        KidsWord(
          emoji: '🎒',
          word: 'bag',
          bangla: 'ব্যাগ',
          sentence: 'This is my bag.',
        ),
        KidsWord(
          emoji: '🥤',
          word: 'cup',
          bangla: 'কাপ',
          sentence: 'Where is my cup?',
        ),
        KidsWord(
          emoji: '📚',
          word: 'book',
          bangla: 'বই',
          sentence: 'This is my book.',
        ),
        KidsWord(
          emoji: '👟',
          word: 'shoe',
          bangla: 'জুতা',
          sentence: 'My shoe is small.',
        ),
        KidsWord(
          emoji: '⚽',
          word: 'ball',
          bangla: 'বল',
          sentence: 'I have a ball.',
        ),
        KidsWord(
          emoji: '🧸',
          word: 'toy',
          bangla: 'খেলনা',
          sentence: 'This is my toy.',
        ),
      ],
      phrases: [
        KidsPhrase(
          text: 'This is my bag.',
          bangla: 'এটা আমার ব্যাগ।',
        ),
        KidsPhrase(
          text: 'Where is my cup?',
          bangla: 'আমার কাপ কোথায়?',
        ),
        KidsPhrase(
          text: 'It is a red ball.',
          bangla: 'এটা একটা লাল বল।',
        ),
      ],
    ),
    KidsWeek(
      number: 3,
      title: 'Colours & Numbers',
      banglaTitle: 'রং ও সংখ্যা',
      focus: 'It is red, two balls, counting 1–3',
      parentTip:
          'রঙ আর সংখ্যা একসাথে শেখান। খেলনা গুনে বলুন — “one ball, two balls”। ভুল হলে হেসে ঠিকটা বলে দিন।',
      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      words: [
        KidsWord(
          emoji: '🔴',
          word: 'red',
          bangla: 'লাল',
          sentence: 'The ball is red.',
        ),
        KidsWord(
          emoji: '🔵',
          word: 'blue',
          bangla: 'নীল',
          sentence: 'The sky is blue.',
        ),
        KidsWord(
          emoji: '🟡',
          word: 'yellow',
          bangla: 'হলুদ',
          sentence: 'The sun is yellow.',
        ),
        KidsWord(
          emoji: '1️⃣',
          word: 'one',
          bangla: 'এক',
          sentence: 'One ball.',
        ),
        KidsWord(
          emoji: '2️⃣',
          word: 'two',
          bangla: 'দুই',
          sentence: 'Two shoes.',
        ),
        KidsWord(
          emoji: '3️⃣',
          word: 'three',
          bangla: 'তিন',
          sentence: 'Three books.',
        ),
      ],
      phrases: [
        KidsPhrase(
          text: 'It is red.',
          bangla: 'এটা লাল।',
        ),
        KidsPhrase(
          text: 'I see two balls.',
          bangla: 'আমি দুটি বল দেখছি।',
        ),
        KidsPhrase(
          text: 'One, two, three!',
          bangla: 'এক, দুই, তিন!',
        ),
      ],
    ),
    KidsWeek(
      number: 4,
      title: 'Family & Feelings',
      banglaTitle: 'পরিবার ও অনুভূতি',
      focus: 'This is my mum, I am happy',
      parentTip:
          'পরিবারের ছবি দেখিয়ে “This is my mum” বলুন। শিশুর মুখভঙ্গি দেখিয়ে “happy”, “sad” বোঝান — অনুবাদ নয়, অভিনয়।',
      colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
      words: [
        KidsWord(
          emoji: '👩',
          word: 'mum',
          bangla: 'মা',
          sentence: 'This is my mum.',
        ),
        KidsWord(
          emoji: '👨',
          word: 'dad',
          bangla: 'বাবা',
          sentence: 'My dad is here.',
        ),
        KidsWord(
          emoji: '😊',
          word: 'happy',
          bangla: 'খুশি',
          sentence: 'I am happy.',
        ),
        KidsWord(
          emoji: '😢',
          word: 'sad',
          bangla: 'দুঃখিত',
          sentence: 'I am sad.',
        ),
        KidsWord(
          emoji: '🍽️',
          word: 'hungry',
          bangla: 'ক্ষুধার্ত',
          sentence: 'I am hungry.',
        ),
        KidsWord(
          emoji: '🥛',
          word: 'thirsty',
          bangla: 'তৃষ্ণার্ত',
          sentence: 'I am thirsty.',
        ),
      ],
      phrases: [
        KidsPhrase(
          text: 'This is my mum.',
          bangla: 'এটি আমার মা।',
        ),
        KidsPhrase(
          text: 'I am happy.',
          bangla: 'আমি খুশি।',
        ),
        KidsPhrase(
          text: 'I am hungry.',
          bangla: 'আমার খিদে লেগেছে।',
        ),
      ],
    ),
    KidsWeek(
      number: 5,
      title: 'School Words',
      banglaTitle: 'স্কুলের কথাবার্তা',
      focus: 'May I..., please, toilet, water',
      parentTip:
          'স্কুলে কাজে লাগবে এমন বাক্য দিনে ২ বার অভিনয় করুন। “May I go to the toilet?” বলার সময় দরজার দিকে ইশারা করুন।',
      colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
      words: [
        KidsWord(
          emoji: '🏫',
          word: 'school',
          bangla: 'স্কুল',
          sentence: 'This is my school.',
        ),
        KidsWord(
          emoji: '🖍️',
          word: 'pencil',
          bangla: 'পেন্সিল',
          sentence: 'This is my pencil.',
        ),
        KidsWord(
          emoji: '💧',
          word: 'water',
          bangla: 'পানি',
          sentence: 'I want water.',
        ),
        KidsWord(
          emoji: '🚻',
          word: 'toilet',
          bangla: 'টয়লেট',
          sentence: 'May I go to the toilet?',
        ),
        KidsWord(
          emoji: '🙏',
          word: 'please',
          bangla: 'দয়া করে',
          sentence: 'Water, please.',
        ),
        KidsWord(
          emoji: '📖',
          word: 'class',
          bangla: 'ক্লাস',
          sentence: 'This is my class.',
        ),
      ],
      phrases: [
        KidsPhrase(
          text: 'May I go to the toilet?',
          bangla: 'আমি টয়লেটে যেতে পারি?',
        ),
        KidsPhrase(
          text: 'Please give me water.',
          bangla: 'দয়া করে আমাকে পানি দিন।',
        ),
        KidsPhrase(
          text: 'Thank you, teacher.',
          bangla: 'ধন্যবাদ, শিক্ষক।',
        ),
      ],
    ),
    KidsWeek(
      number: 6,
      title: 'Food & Drink',
      banglaTitle: 'খাবার ও পানীয়',
      focus: 'I want..., I like...',
      parentTip:
          'খাওয়ার সময়টাই সবচেয়ে ভালো সময়। প্লেটের দিকে দেখিয়ে বলুন — “I like rice”, “I want milk”।',
      colors: [Color(0xFFFB923C), Color(0xFFEA580C)],
      words: [
        KidsWord(
          emoji: '🍎',
          word: 'apple',
          bangla: 'আপেল',
          sentence: 'I like apples.',
        ),
        KidsWord(
          emoji: '🥛',
          word: 'milk',
          bangla: 'দুধ',
          sentence: 'I want milk.',
        ),
        KidsWord(
          emoji: '🍚',
          word: 'rice',
          bangla: 'ভাত',
          sentence: 'This is rice.',
        ),
        KidsWord(
          emoji: '🥚',
          word: 'egg',
          bangla: 'ডিম',
          sentence: 'I have an egg.',
        ),
        KidsWord(
          emoji: '🍌',
          word: 'banana',
          bangla: 'কলা',
          sentence: 'The banana is yellow.',
        ),
        KidsWord(
          emoji: '🍞',
          word: 'bread',
          bangla: 'রুটি',
          sentence: 'I want bread.',
        ),
      ],
      phrases: [
        KidsPhrase(
          text: 'I want milk.',
          bangla: 'আমি দুধ চাই।',
        ),
        KidsPhrase(
          text: 'I like apples.',
          bangla: 'আমি আপেল পছন্দ করি।',
        ),
        KidsPhrase(
          text: 'No, thank you.',
          bangla: 'না, ধন্যবাদ।',
        ),
      ],
    ),
    KidsWeek(
      number: 7,
      title: 'Animals & Actions',
      banglaTitle: 'প্রাণী ও কাজ',
      focus: 'The cat runs, I can jump',
      parentTip:
          'কথা বলার সাথে কাজ দেখান — লাফ দিন, দৌড়ান, বসুন। শরীর নড়ালে শিশু বাক্যটি দ্রুত মনে রাখে।',
      colors: [Color(0xFF2DD4BF), Color(0xFF0D9488)],
      words: [
        KidsWord(
          emoji: '🐱',
          word: 'cat',
          bangla: 'বিড়াল',
          sentence: 'The cat runs.',
        ),
        KidsWord(
          emoji: '🐶',
          word: 'dog',
          bangla: 'কুকুর',
          sentence: 'The dog jumps.',
        ),
        KidsWord(
          emoji: '🐦',
          word: 'bird',
          bangla: 'পাখি',
          sentence: 'The bird can fly.',
        ),
        KidsWord(
          emoji: '🏃',
          word: 'run',
          bangla: 'দৌড়ানো',
          sentence: 'I can run.',
        ),
        KidsWord(
          emoji: '🦘',
          word: 'jump',
          bangla: 'লাফানো',
          sentence: 'I can jump.',
        ),
        KidsWord(
          emoji: '🪑',
          word: 'sit',
          bangla: 'বসা',
          sentence: 'Sit down, please.',
        ),
      ],
      phrases: [
        KidsPhrase(
          text: 'The cat runs.',
          bangla: 'বিড়ালটি দৌড়ায়।',
        ),
        KidsPhrase(
          text: 'I can jump.',
          bangla: 'আমি লাফাতে পারি।',
        ),
        KidsPhrase(
          text: 'Sit down, please.',
          bangla: 'বসুন, দয়া করে।',
        ),
      ],
    ),
    KidsWeek(
      number: 8,
      title: 'Story Time',
      banglaTitle: 'গল্পের সময়',
      focus: 'Look, listen, big/small, simple story',
      parentTip:
          'ছবির বই নিয়ে বসুন। গল্প বলার সময় থেমে প্রশ্ন করুন — “What is the cat doing?” শিশু ২–৩ শব্দে উত্তর দিলেই যথেষ্ট।',
      colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
      words: [
        KidsWord(
          emoji: '🐘',
          word: 'big',
          bangla: 'বড়',
          sentence: 'The elephant is big.',
        ),
        KidsWord(
          emoji: '🐜',
          word: 'small',
          bangla: 'ছোট',
          sentence: 'The ant is small.',
        ),
        KidsWord(
          emoji: '👀',
          word: 'look',
          bangla: 'দেখা',
          sentence: 'Look at me.',
        ),
        KidsWord(
          emoji: '👂',
          word: 'listen',
          bangla: 'শোনা',
          sentence: 'Listen to me.',
        ),
        KidsWord(
          emoji: '🚶',
          word: 'go',
          bangla: 'যাওয়া',
          sentence: "Let's go!",
        ),
        KidsWord(
          emoji: '🛑',
          word: 'stop',
          bangla: 'থামা',
          sentence: 'Stop here.',
        ),
      ],
      phrases: [
        KidsPhrase(
          text: 'Look at me.',
          bangla: 'আমার দিকে তাকাও।',
        ),
        KidsPhrase(
          text: 'Listen to me.',
          bangla: 'আমার কথা শোনো।',
        ),
        KidsPhrase(
          text: 'The elephant is big and the ant is small.',
          bangla: 'হাতিটি বড় আর পিঁপড়াটি ছোট।',
        ),
      ],
    ),
  ];

  static KidsWeek weekByNumber(int number) =>
      weeks.firstWhere((week) => week.number == number, orElse: () => weeks.first);
}

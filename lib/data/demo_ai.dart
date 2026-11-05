import 'dart:math' as math;

import '../core/constants.dart';
import 'catalog.dart';
import 'models.dart';

/// A fully local coaching engine. It keeps the app useful when no Gemini key is
/// configured, when the user is offline, or when every API key hits its quota.
class DemoAi {
  DemoAi._();

  static final Map<String, List<String>> _followUps = {
    'meet-someone': [
      'Nice to meet you! So, what do you do when you are not at the club?',
      'That sounds fun. How long have you been learning English?',
      'I like your energy! What is one thing you want to improve this month?',
      'Tell me more — what made you join this club?',
    ],
    'restaurant': [
      'Of course. Would you like to hear today\'s specials, or are you ready to order?',
      'Good choice. How would you like that cooked, and would you like anything with it?',
      'I will bring that right away. Can I get you anything else while you wait?',
      'Here is your bill. Would you like to pay by card or cash?',
    ],
    'campus': [
      'Same here! I think we should divide the slides. Which part do you want to take?',
      'That makes sense. When should we meet to practise the presentation?',
      'Good plan. Do you think we should ask the lecturer about the deadline?',
      'Perfect. I will send the draft tonight — can you review it tomorrow?',
    ],
    'job-interview': [
      'Thanks, that gives me a good picture. Can you tell me about a time you solved a difficult problem?',
      'Good. What would you say is your biggest strength, and can you give me an example?',
      'I see. Why are you interested in this role specifically?',
      'Thanks. What questions do you have for me about the team or the work?',
    ],
    'work-meeting': [
      'Thanks for the update. What is blocking the team right now, and what do you need from me?',
      'I hear you. If we move the deadline by one week, what would change?',
      'That is fair. How do you want to split the remaining work?',
      'Good. Let\'s confirm the next steps and who owns each one.',
    ],
    'airport': [
      'Thank you. Are you checking in any bags today?',
      'Your gate is B12. Boarding starts at 3:40. Do you have any questions?',
      'There is a short delay. Would you like me to check if you can catch the earlier flight?',
      'All set. Please keep your passport and boarding pass ready at security.',
    ],
    'faulty-gadget': [
      'I\'m sorry to hear that. When did you buy it, and do you have the receipt?',
      'I understand. Would you prefer a replacement or a refund?',
      'Let me check the warranty. Could you describe the fault in a little more detail?',
      'I can process that today. It should take about five minutes.',
    ],
    'doctor': [
      'I see. How long have you had these symptoms?',
      'Have you taken any medicine for it so far?',
      'Thanks. I would like you to rest and drink plenty of water. Any questions?',
      'If it gets worse, please come back. Does that sound okay?',
    ],
    'ielts-mock': [
      'Thank you. Now let\'s move to Part 2. You have one minute to prepare.',
      'Interesting. Why do you think that is the case?',
      'Can you give me a specific example from your own experience?',
      'Thank you. That is the end of the speaking test.',
    ],
    'salary': [
      'Thanks for being direct. Can you walk me through how you arrived at that number?',
      'I understand. If we cannot quite reach that, what else would make the offer work for you?',
      'That is helpful. Let me check with the team and come back to you.',
      'We can work with that. I will send the revised offer today.',
    ],
  };

  static final Map<String, String> _scenarioVocab = {
    'meet-someone': 'break the ice',
    'restaurant': 'grab a bite',
    'campus': 'on the same page',
    'job-interview': 'prioritise',
    'work-meeting': 'follow up',
    'airport': 'hit the road',
    'faulty-gadget': 'follow up',
    'doctor': 'under the weather',
    'ielts-mock': 'touch base',
    'salary': 'propose',
  };

  static final List<({RegExp pattern, String replacement, String tip})> _fixes = [
    (
      pattern: RegExp(r'\bi am agree\b', caseSensitive: false),
      replacement: 'I agree',
      tip: '“Agree” নিজেই একটি verb, তাই “am” লাগে না। বলুন: I agree.',
    ),
    (
      pattern: RegExp(r'\bi go yesterday\b', caseSensitive: false),
      replacement: 'I went yesterday',
      tip: 'yesterday অতীত সময়, তাই go নয় — went ব্যবহার করুন।',
    ),
    (
      pattern: RegExp(r"\b(he|she) don't\b", caseSensitive: false),
      replacement: 'he/she doesn\'t',
      tip: 'He/She এর সাথে does/doesn’t ব্যবহার হয়, do/don’t নয়।',
    ),
    (
      pattern: RegExp(r"\bi didn't went\b", caseSensitive: false),
      replacement: "I didn't go",
      tip: 'didn’t এর পরে verb-এর base form হয়: didn’t go.',
    ),
    (
      pattern: RegExp(r'\bmore better\b', caseSensitive: false),
      replacement: 'better',
      tip: '“Better” নিজেই comparative, তাই “more” যোগ করবেন না।',
    ),
    (
      pattern: RegExp(r'\bdiscuss about\b', caseSensitive: false),
      replacement: 'discuss',
      tip: '“Discuss” এর পরে “about” লাগে না: discuss the plan.',
    ),
    (
      pattern: RegExp(r'\breturn back\b', caseSensitive: false),
      replacement: 'return',
      tip: '“Return” মানেই ফিরে আসা; আবার “back” বলার দরকার নেই।',
    ),
    (
      pattern: RegExp(r'\bexplain me\b', caseSensitive: false),
      replacement: 'explain to me',
      tip: 'কাউকে কিছু বোঝাতে “explain to me” বলুন, “explain me” নয়।',
    ),
    (
      pattern: RegExp(r'\bi am living here since\b', caseSensitive: false),
      replacement: 'I have been living here since',
      tip: 'since/for দিয়ে চলমান সময় বোঝালে present perfect continuous ব্যবহার করুন।',
    ),
  ];

  static AiReply reply({
    required Persona persona,
    required Scenario scenario,
    required List<ChatTurn> history,
    required String userText,
    required CefrLevel level,
    required bool banglaMode,
  }) {
    final text = userText.trim();
    final fix = _detectFix(text);
    final questions = _followUps[scenario.id] ?? _followUps['meet-someone']!;
    final turnIndex = math.max(0, (history.where((t) => t.role == ChatRole.ai).length - 1));
    final question = questions[turnIndex % questions.length];
    final lower = text.toLowerCase();
    final isGreeting = RegExp(r'^(hi|hello|hey|good morning|good evening|salam)')
        .hasMatch(lower);
    final words = AppUtils.wordCount(text);
    final fillers = AppUtils.countFillers(text);

    final buffer = StringBuffer();
    if (isGreeting && turnIndex < 1) {
      buffer.write('Hi! It\'s really nice to meet you. ');
    } else if (words < 4 && text.isNotEmpty) {
      buffer.write('Good start — let\'s build on that. ');
    } else {
      buffer.write(_acknowledgements[turnIndex % _acknowledgements.length]);
      buffer.write(' ');
    }

    if (fix != null) {
      buffer.write('A more natural way to say that is: “${fix.corrected}”. ');
    } else if (text.isNotEmpty && words >= 6) {
      buffer.write('I like how clearly you explained that. ');
    }

    buffer.write(question);

    final betterWay = fix?.corrected ?? _polish(text);
    final vocab = _scenarioVocab[scenario.id] ?? 'break the ice';
    final banglaTip = _tipFor(text, fix, fillers, banglaMode);

    return AiReply(
      reply: buffer.toString().trim(),
      emotion: _emotionFor(scenario.id),
      betterWay: betterWay,
      casualTone: _tone(text, VocabTone.casual),
      formalTone: _tone(text, VocabTone.formal),
      idiomaticTone: _tone(text, VocabTone.idiomatic),
      banglaTip: banglaTip,
      vocabWord: vocab,
      hintForUser: scenario.goals[turnIndex % scenario.goals.length],
      correction: fix?.corrected ?? '',
    );
  }

  static AiReply opening({
    required Persona persona,
    required Scenario scenario,
    required bool banglaMode,
  }) {
    final text = scenario.openingLine;
    return AiReply(
      reply: text,
      emotion: scenario.id == 'job-interview' ? 'curious' : 'happy',
      betterWay: '',
      banglaTip: banglaMode
          ? 'উত্তর দেওয়ার সময় ছোট ছোট বাক্যে বলুন। আতঙ্ক নয় — একটু একটু করে বললেই হবে।'
          : 'Take your time. Answer with one clear sentence, then add a reason.',
      hintForUser: scenario.goals.first,
    );
  }

  static final List<String> _acknowledgements = [
    'That sounds interesting.',
    'I see what you mean.',
    'Thanks for sharing that.',
    'Nice — that gives me a clearer picture.',
    'Good point.',
  ];

  static String _emotionFor(String scenarioId) => switch (scenarioId) {
        'job-interview' || 'salary' => 'curious',
        'doctor' => 'caring',
        'ielts-mock' => 'focused',
        'faulty-gadget' => 'attentive',
        _ => 'encouraging',
      };

  static _Fix? _detectFix(String text) {
    if (text.isEmpty) return null;
    for (final fix in _fixes) {
      if (fix.pattern.hasMatch(text)) {
        return _Fix(
          corrected: text.replaceAll(fix.pattern, fix.replacement),
          tip: fix.tip,
        );
      }
    }
    return null;
  }

  static String _polish(String text) {
    if (text.trim().isEmpty) return '';
    var value = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    value = AppUtils.capitalize(value);
    if (!RegExp(r'[.!?]$').hasMatch(value)) value = '$value.';
    return value;
  }

  static String _tone(String text, VocabTone tone) {
    final base = _polish(text);
    if (base.isEmpty) return '';
    final lower = base[0].toLowerCase() + base.substring(1);
    return switch (tone) {
      VocabTone.casual => 'Honestly, $lower You know how it is.',
      VocabTone.formal => 'To be precise, $lower I would be happy to elaborate if needed.',
      VocabTone.idiomatic =>
        'Long story short, $lower That is basically the whole picture.',
    };
  }

  static String _tipFor(String text, _Fix? fix, int fillers, bool banglaMode) {
    if (fix != null) return fix.tip;
    if (fillers >= 2) {
      return 'আপনি “um / uh / like” বেশ কয়েকবার ব্যবহার করেছেন। এক সেকেন্ড থেমে নিঃশ্বাস নিন, তারপর পরের বাক্য শুরু করুন।';
    }
    if (AppUtils.wordCount(text) < 5) {
      return 'উত্তরটি একটু ছোট হয়েছে। একটি কারণ (“because…”) বা একটি উদাহরণ যোগ করুন।';
    }
    if (banglaMode) {
      return 'বাংলায় ভাবতে পারেন, কিন্তু ইংরেজিতে বলার সময় ছোট বাক্য ব্যবহার করুন — এটি বেশি স্বাভাবিক শোনায়।';
    }
    return 'ভালো বলেছেন! এখন উত্তরটি আরও প্রাণবন্ত করতে একটি উদাহরণ বা ব্যক্তিগত অভিজ্ঞতা যোগ করুন।';
  }
}

class _Fix {
  const _Fix({required this.corrected, required this.tip});
  final String corrected;
  final String tip;
}

/// Helper used by richer demo content.
String randomVocabForScenario(String scenarioId) =>
    DemoAi._scenarioVocab[scenarioId] ?? Catalog.vocabulary.first.word;

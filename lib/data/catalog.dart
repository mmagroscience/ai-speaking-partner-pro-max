import 'package:flutter/material.dart';

import 'models.dart';

class Catalog {
  Catalog._();

  static const goals = AppGoal.values;

  static const personas = <Persona>[
    Persona(
      id: 'sarah',
      name: 'Sarah',
      role: 'Friendly Tutor',
      accent: 'US Accent',
      tagline: 'Warm, patient, and always cheering you on.',
      greeting: "Hey! I'm Sarah. Ready for a relaxed chat about your day?",
      emoji: 'S',
      colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
    ),
    Persona(
      id: 'alex',
      name: 'Alex',
      role: 'Hiring Manager',
      accent: 'UK British Accent',
      tagline: 'Sharp interview questions with practical feedback.',
      greeting:
          "Good morning. Thanks for making the time today. Shall we start with your background?",
      emoji: 'A',
      colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
    ),
    Persona(
      id: 'maya',
      name: 'Maya',
      role: 'Casual Best Friend',
      accent: 'Australian Accent',
      tagline: 'Easy-going chats about food, friends, and life.',
      greeting:
          "Heyyy! You made it! Okay, tell me everything — what's been going on?",
      emoji: 'M',
      colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
    ),
    Persona(
      id: 'james',
      name: 'Prof. James',
      role: 'IELTS Examiner',
      accent: 'UK Accent',
      tagline: 'Official-style Part 1, 2, 3 practice with band feedback.',
      greeting:
          "Good morning. This is the IELTS speaking test. Let's begin with Part 1.",
      emoji: 'J',
      colors: [Color(0xFF34D399), Color(0xFF059669)],
    ),
    Persona(
      id: 'custom',
      name: 'Familiar Person',
      role: 'Your own AI clone',
      accent: 'Custom voice',
      tagline: 'Upload a photo and a voice sample of someone you know.',
      greeting: 'Hey, it\'s me. Come on, tell me what happened today.',
      emoji: '+',
      colors: [Color(0xFFF472B6), Color(0xFFDB2777)],
      isCustom: true,
    ),
  ];

  static Persona personaById(String id) => personas.firstWhere(
        (p) => p.id == id,
        orElse: () => personas.first,
      );

  static const categories = [
    'All topics',
    'Everyday English',
    'Study & campus',
    'Job interviews',
    'Work & business',
    'Travel & abroad',
    'IELTS speaking',
  ];

  static const scenarios = <Scenario>[
    Scenario(
      id: 'meet-someone',
      title: 'Meet someone new',
      subtitle: 'First impressions & small talk',
      category: 'Everyday English',
      description:
          'Practise introducing yourself, asking friendly questions, and keeping a conversation alive.',
      aiRole: 'A new classmate at a language club',
      openingLine:
          "Hi! I don't think we've met before. I'm Sarah — I just joined the club. What's your name?",
      emoji: '👋',
      level: CefrLevel.beginner,
      goals: ['Introduce yourself', 'Ask follow-up questions', 'Use polite small talk'],
      colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
      personaId: 'sarah',
    ),
    Scenario(
      id: 'restaurant',
      title: 'At a restaurant',
      subtitle: 'Ordering, asking & paying',
      category: 'Travel & abroad',
      description:
          'Order a meal, ask about the menu, handle a small problem, and ask for the bill.',
      aiRole: 'A friendly waiter in a busy restaurant',
      openingLine:
          'Good evening! Welcome in. Can I get you something to drink while you look at the menu?',
      emoji: '🍽️',
      level: CefrLevel.beginner,
      goals: ['Order politely', 'Ask about ingredients', 'Handle the bill'],
      colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
      personaId: 'maya',
    ),
    Scenario(
      id: 'campus',
      title: 'Campus conversation',
      subtitle: 'Classes, assignments & projects',
      category: 'Study & campus',
      description:
          'Talk to a classmate about a deadline, a group project, and what the lecturer said.',
      aiRole: 'Your project partner, Maya',
      openingLine:
          'Hey! Did you understand what the lecturer said about the group presentation? I am a bit lost.',
      emoji: '🎓',
      level: CefrLevel.beginner,
      goals: ['Explain a problem', 'Make a plan', 'Ask for clarification'],
      colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
      personaId: 'maya',
    ),
    Scenario(
      id: 'job-interview',
      title: 'Job interview',
      subtitle: 'Strengths, examples & salary',
      category: 'Job interviews',
      description:
          'A realistic interview with STAR-style follow-ups and instant feedback on your answers.',
      aiRole: 'Alex, a hiring manager',
      openingLine:
          "Good morning. Thanks for coming in. To start, could you tell me a little about yourself and what you're doing now?",
      emoji: '💼',
      level: CefrLevel.intermediate,
      goals: ['Tell your story', 'Use STAR examples', 'Ask smart questions'],
      colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
      personaId: 'alex',
    ),
    Scenario(
      id: 'work-meeting',
      title: 'Work meeting',
      subtitle: 'Updates, opinions & deadlines',
      category: 'Work & business',
      description:
          'Give a project update, disagree politely, and agree on next steps with your manager.',
      aiRole: 'Alex, your team lead',
      openingLine:
          "Thanks for joining. Let's start with your update on the client project. Where are we this week?",
      emoji: '📊',
      level: CefrLevel.intermediate,
      goals: ['Give a clear update', 'Disagree politely', 'Confirm next steps'],
      colors: [Color(0xFF34D399), Color(0xFF059669)],
      personaId: 'alex',
    ),
    Scenario(
      id: 'airport',
      title: 'At the airport',
      subtitle: 'Check-in, boarding & immigration',
      category: 'Travel & abroad',
      description:
          'Check in for a flight, ask about a delay, and answer immigration questions calmly.',
      aiRole: 'An airline check-in agent',
      openingLine:
          'Good afternoon. May I see your passport and booking confirmation, please?',
      emoji: '✈️',
      level: CefrLevel.beginner,
      goals: ['Check in smoothly', 'Ask about a delay', 'Answer questions clearly'],
      colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
      personaId: 'sarah',
    ),
    Scenario(
      id: 'faulty-gadget',
      title: 'Return a faulty gadget',
      subtitle: 'Complaining politely',
      category: 'Everyday English',
      description:
          'Explain the problem, ask for a replacement, and stay polite when the shop pushes back.',
      aiRole: 'A shop assistant',
      openingLine:
          'Hello, how can I help? Is there a problem with your purchase?',
      emoji: '🎧',
      level: CefrLevel.intermediate,
      goals: ['Describe the fault', 'Ask for a refund', 'Stay polite but firm'],
      colors: [Color(0xFFF472B6), Color(0xFFDB2777)],
      personaId: 'maya',
    ),
    Scenario(
      id: 'doctor',
      title: 'See a doctor',
      subtitle: 'Symptoms & advice',
      category: 'Everyday English',
      description:
          'Describe how you feel, answer the doctor\'s questions, and understand the advice.',
      aiRole: 'A friendly doctor',
      openingLine:
          "Come in, take a seat. So, what seems to be the problem today?",
      emoji: '🩺',
      level: CefrLevel.intermediate,
      goals: ['Describe symptoms', 'Ask about medicine', 'Understand next steps'],
      colors: [Color(0xFF34D399), Color(0xFF0D9488)],
      personaId: 'sarah',
    ),
    Scenario(
      id: 'ielts-mock',
      title: 'IELTS speaking mock',
      subtitle: 'Part 1, 2 & band estimate',
      category: 'IELTS speaking',
      description:
          'A timed exam simulation with cue card, follow-up questions, and an estimated band score.',
      aiRole: 'Prof. James, IELTS examiner',
      openingLine:
          "Good morning. Let's begin. Part 1: Where are you from, and what do you like about your hometown?",
      emoji: '🏆',
      level: CefrLevel.advanced,
      goals: ['Speak for 2 minutes', 'Use linking words', 'Reduce fillers'],
      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      personaId: 'james',
    ),
    Scenario(
      id: 'salary',
      title: 'Salary negotiation',
      subtitle: 'Value, numbers & confidence',
      category: 'Work & business',
      description:
          'Discuss a job offer, justify your expected salary, and negotiate without sounding aggressive.',
      aiRole: 'Alex, a hiring manager',
      openingLine:
          "We're excited to move forward. Before we finalise, what are your salary expectations?",
      emoji: '🤝',
      level: CefrLevel.advanced,
      goals: ['State a number', 'Justify your value', 'Stay collaborative'],
      colors: [Color(0xFFA78BFA), Color(0xFF6D28D9)],
      personaId: 'alex',
    ),
  ];

  static Scenario scenarioById(String id) => scenarios.firstWhere(
        (s) => s.id == id,
        orElse: () => scenarios.first,
      );

  static const phrases = <Phrase>[
    Phrase(
      text: 'I think this is the right thing to do.',
      ipa: '/aɪ θɪŋk ðɪs ɪz ðə raɪt θɪŋ tə duː/',
      banglaTip:
          '“th” ধ্বনিতে জিভের ডগা দাঁতের ফাঁকে হালকা স্পর্শ করবে। “thing” ও “think” — দুটোতেই এই শব্দ।',
      focus: 'th sound',
    ),
    Phrase(
      text: 'I would love to visit a very beautiful village.',
      ipa: '/aɪ wʊd lʌv tə ˈvɪzɪt ə ˈveri ˈbjuːtɪfəl ˈvɪlɪdʒ/',
      banglaTip:
          '“v” উচ্চারণে নিচের ঠোঁট দাঁতে হালকা লাগবে; “w” এ ঠোঁট গোল হবে। Very ≠ Wery।',
      focus: 'V vs W',
    ),
    Phrase(
      text: 'She walked home and watched the sunset.',
      ipa: '/ʃiː wɔːkt hoʊm ænd wɒtʃt ðə ˈsʌnset/',
      banglaTip:
          '“-ed” এখানে “t” এর মতো শোনায়: walkt, watcht। “-ed” সবসময় “এড” নয়।',
      focus: '-ed endings',
    ),
    Phrase(
      text: 'Could you hand me the blue notebook?',
      ipa: '/kʊd juː hænd miː ðə bluː ˈnoʊtbʊk/',
      banglaTip:
          'প্রশ্নের শুরুতে “could” নরমভাবে বলুন — এটি “কুড” নয়, বরং “কুড” এর হালকা রূপ।',
      focus: 'Connected speech',
    ),
    Phrase(
      text: 'I have been meaning to call you all week.',
      ipa: '/aɪ hæv biːn ˈmiːnɪŋ tə kɔːl juː ɔːl wiːk/',
      banglaTip:
          '“have been -ing” দিয়ে বোঝায় কাজটা কিছু সময় ধরে চলছে। এখানে “been” কে “বিন” বলুন, “বীন” নয়।',
      focus: 'Present perfect continuous',
    ),
    Phrase(
      text: 'The weather is rather pleasant this evening.',
      ipa: '/ðə ˈweðər ɪz ˈræðər ˈplezənt ðɪs ˈiːvnɪŋ/',
      banglaTip:
          '“weather” এ “th” নরম (ভয়েসড), “rather” এও একই। “w” দিয়ে শুরু করবেন না।',
      focus: 'Voiced th',
    ),
    Phrase(
      text: 'I am used to working late on Fridays.',
      ipa: '/aɪ æm juːst tə ˈwɜːrkɪŋ leɪt ɒn ˈfraɪdeɪz/',
      banglaTip:
          '“used to + verb-ing” মানে অভ্যস্ত হওয়া। এখানে “used” এর শেষে “t” শব্দ আছে।',
      focus: 'Used to',
    ),
    Phrase(
      text: 'Would you mind speaking a little more slowly?',
      ipa: '/wʊd juː maɪnd ˈspiːkɪŋ ə ˈlɪtl mɔːr ˈsloʊli/',
      banglaTip:
          '“Would you mind + -ing” ভদ্র অনুরোধ। “little” এ দুইবার “t” হালকা হবে, প্রায় “লিডল”।',
      focus: 'Polite requests',
    ),
  ];

  static const vocabulary = <VocabWord>[
    VocabWord(
      word: 'chill',
      phonetic: '/tʃɪl/',
      meaningBn: 'আরাম করা, চাপমুক্ত সময় কাটানো',
      meaningEn: 'to relax and do nothing stressful',
      example: 'We just chilled at home and watched a movie.',
      tone: VocabTone.casual,
      tip: 'Close friends with “hang out”, but “chill” sounds more relaxed.',
    ),
    VocabWord(
      word: 'grab a bite',
      phonetic: '/ɡræb ə baɪt/',
      meaningBn: 'দ্রুত কিছু খাওয়া',
      meaningEn: 'to eat a quick meal',
      example: 'Do you want to grab a bite after class?',
      tone: VocabTone.casual,
      tip: 'Very natural for lunch or a quick snack with friends.',
    ),
    VocabWord(
      word: 'catch up',
      phonetic: '/kætʃ ʌp/',
      meaningBn: 'অনেকদিন পর খোঁজখবর নেওয়া',
      meaningEn: 'to talk with someone after a long time',
      example: 'Let\'s catch up over coffee next week.',
      tone: VocabTone.casual,
      tip: 'You can also say “catch up on work” meaning to finish delayed work.',
    ),
    VocabWord(
      word: 'no worries',
      phonetic: '/noʊ ˈwɜːriz/',
      meaningBn: 'কোনো সমস্যা নেই',
      meaningEn: 'it is not a problem',
      example: 'No worries, I can send it tomorrow.',
      tone: VocabTone.casual,
      tip: 'Friendly and common in Australia and the UK.',
    ),
    VocabWord(
      word: 'hit the road',
      phonetic: '/hɪt ðə roʊd/',
      meaningBn: 'রওনা দেওয়া',
      meaningEn: 'to start a journey or leave',
      example: 'It\'s getting late — we should hit the road.',
      tone: VocabTone.casual,
      tip: 'Use it with friends; not in a formal email.',
    ),
    VocabWord(
      word: 'hang out',
      phonetic: '/hæŋ aʊt/',
      meaningBn: 'সময় কাটানো',
      meaningEn: 'to spend time with people casually',
      example: 'We hung out at the lake all afternoon.',
      tone: VocabTone.casual,
      tip: 'Past form is “hung out”, not “hanged out”.',
    ),
    VocabWord(
      word: 'follow up',
      phonetic: '/ˈfɒloʊ ʌp/',
      meaningBn: 'পরে আবার যোগাযোগ করা',
      meaningEn: 'to check on something after some time',
      example: 'I will follow up with the client on Monday.',
      tone: VocabTone.formal,
      tip: 'As a noun: “a follow-up email”. As a verb: “follow up with someone”.',
    ),
    VocabWord(
      word: 'prioritise',
      phonetic: '/praɪˈɒrətaɪz/',
      meaningBn: 'গুরুত্ব অনুযায়ী আগে করা',
      meaningEn: 'to decide what is most important',
      example: 'We need to prioritise the tasks with the biggest impact.',
      tone: VocabTone.formal,
      tip: 'US spelling is “prioritize”; both are correct.',
    ),
    VocabWord(
      word: 'coordinate',
      phonetic: '/koʊˈɔːrdɪneɪt/',
      meaningBn: 'সমন্বয় করা',
      meaningEn: 'to organise people or activities together',
      example: 'I will coordinate with the design team and share an update.',
      tone: VocabTone.formal,
      tip: 'Very common in meetings and project updates.',
    ),
    VocabWord(
      word: 'appreciate',
      phonetic: '/əˈpriːʃieɪt/',
      meaningBn: 'কদর করা, ধন্যবাদ জানানো',
      meaningEn: 'to be thankful for something',
      example: 'I really appreciate your quick response.',
      tone: VocabTone.formal,
      tip: '“I appreciate it” is warmer than “Thanks” in a formal email.',
    ),
    VocabWord(
      word: 'propose',
      phonetic: '/prəˈpoʊz/',
      meaningBn: 'প্রস্তাব দেওয়া',
      meaningEn: 'to suggest a plan or idea',
      example: 'I propose that we move the launch to next Tuesday.',
      tone: VocabTone.formal,
      tip: 'Use “propose + that + subject + verb” for a formal suggestion.',
    ),
    VocabWord(
      word: 'clarify',
      phonetic: '/ˈklærəfaɪ/',
      meaningBn: 'স্পষ্ট করা',
      meaningEn: 'to make something easier to understand',
      example: 'Could you clarify what you mean by the second point?',
      tone: VocabTone.formal,
      tip: 'A polite way to ask again without saying “I don’t understand”.',
    ),
    VocabWord(
      word: 'break the ice',
      phonetic: '/breɪk ði aɪs/',
      meaningBn: 'আলাপের পরিবেশ সহজ করা',
      meaningEn: 'to make people feel comfortable at the start',
      example: 'I told a small joke to break the ice.',
      tone: VocabTone.idiomatic,
      tip: 'Perfect for the first minute of a meeting or a date.',
    ),
    VocabWord(
      word: 'on the same page',
      phonetic: '/ɒn ðə seɪm peɪdʒ/',
      meaningBn: 'একই বোঝাপড়ায় থাকা',
      meaningEn: 'to agree about what is happening',
      example: 'Let\'s make sure we are all on the same page before we start.',
      tone: VocabTone.idiomatic,
      tip: 'Common in offices; it means “we agree”, not “we are reading”.',
    ),
    VocabWord(
      word: 'get the ball rolling',
      phonetic: '/ɡet ðə bɔːl ˈroʊlɪŋ/',
      meaningBn: 'কাজ শুরু করা',
      meaningEn: 'to start an activity or process',
      example: 'I\'ll get the ball rolling by sharing the first draft.',
      tone: VocabTone.idiomatic,
      tip: 'Use it when you want to begin a project or discussion.',
    ),
    VocabWord(
      word: 'under the weather',
      phonetic: '/ˈʌndər ðə ˈweðər/',
      meaningBn: 'একটু অসুস্থ বোধ করা',
      meaningEn: 'feeling slightly ill',
      example: 'I\'m feeling a bit under the weather today.',
      tone: VocabTone.idiomatic,
      tip: 'It does not mean the weather is bad. Use it about your health.',
    ),
    VocabWord(
      word: 'cut to the chase',
      phonetic: '/kʌt tə ðə tʃeɪs/',
      meaningBn: 'মূল কথায় আসা',
      meaningEn: 'to get to the important point quickly',
      example: 'Let\'s cut to the chase — what do you need from me?',
      tone: VocabTone.idiomatic,
      tip: 'Direct but can sound rude in a very formal meeting.',
    ),
    VocabWord(
      word: 'touch base',
      phonetic: '/tʌtʃ beɪs/',
      meaningBn: 'সংক্ষেপে যোগাযোগ করা',
      meaningEn: 'to contact someone briefly to share an update',
      example: 'I\'ll touch base with you after the client call.',
      tone: VocabTone.idiomatic,
      tip: 'Business idiom; “touch base with someone” is the full pattern.',
    ),
  ];

  static const ieltsPart1 = [
    'Where are you from, and what do you like about your hometown?',
    'Do you work or are you a student?',
    'What do you usually do in your free time?',
    'Do you prefer mornings or evenings? Why?',
    'How often do you use public transport?',
    'What kind of music do you enjoy listening to?',
  ];

  static const ieltsCueCards = <CueCard>[
    CueCard(
      topic: 'Describe a person who has influenced you',
      points: [
        'who this person is',
        'how you know them',
        'what they have done',
        'and explain why they influenced you',
      ],
    ),
    CueCard(
      topic: 'Describe a memorable journey',
      points: [
        'where you went',
        'who you travelled with',
        'what happened during the trip',
        'and explain why it was memorable',
      ],
    ),
    CueCard(
      topic: 'Describe a skill you want to learn',
      points: [
        'what the skill is',
        'why you want to learn it',
        'how you plan to learn it',
        'and explain how it would help you',
      ],
    ),
    CueCard(
      topic: 'Describe a time you solved a difficult problem',
      points: [
        'what the problem was',
        'how you felt at the time',
        'what you did to solve it',
        'and explain what you learned',
      ],
    ),
  ];

  static const ieltsPart3 = [
    'Why do some people find it difficult to learn a new language?',
    'How has technology changed the way people communicate?',
    'Do you think schools should teach more practical skills?',
    'What are the advantages of living in a big city?',
    'Should companies allow employees to work from home?',
    'How can governments encourage people to be more active?',
  ];

  static const achievements = <Achievement>[
    Achievement(
      id: 'first-call',
      title: 'First hello',
      description: 'Complete your first AI video call.',
      icon: Icons.video_call_outlined,
      target: 1,
    ),
    Achievement(
      id: 'streak-3',
      title: '3-day streak',
      description: 'Practise three days in a row.',
      icon: Icons.local_fire_department_outlined,
      target: 3,
    ),
    Achievement(
      id: 'streak-7',
      title: 'One week strong',
      description: 'Keep a 7-day speaking streak.',
      icon: Icons.whatshot_outlined,
      target: 7,
    ),
    Achievement(
      id: 'ten-calls',
      title: 'Conversation pro',
      description: 'Finish 10 speaking sessions.',
      icon: Icons.forum_outlined,
      target: 10,
    ),
    Achievement(
      id: 'pron-90',
      title: 'Clear speaker',
      description: 'Score 90+ in Pronunciation Lab.',
      icon: Icons.record_voice_over_outlined,
      target: 90,
    ),
  ];
}

class CueCard {
  const CueCard({required this.topic, required this.points});
  final String topic;
  final List<String> points;
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int target;
}

/// Hand-written extras that the Oxford 3000 dataset does not ship with.
///
/// Only common words get entries; cards without extras simply hide those
/// sections, so the back of the card never shows an empty heading.
class FlashExtras {
  const FlashExtras({
    this.synonyms = const [],
    this.antonyms = const [],
    this.phrases = const [],
  });

  final List<String> synonyms;
  final List<String> antonyms;
  final List<String> phrases;
}

const flashExtras = <String, FlashExtras>{
  'happy': FlashExtras(
    synonyms: ['glad', 'cheerful', 'joyful'],
    antonyms: ['sad', 'unhappy'],
    phrases: ['happy birthday', 'happy ending', 'so happy for you'],
  ),
  'sad': FlashExtras(
    synonyms: ['unhappy', 'down', 'upset'],
    antonyms: ['happy', 'cheerful'],
    phrases: ['feel sad', 'sad news', "don't be sad"],
  ),
  'big': FlashExtras(
    synonyms: ['large', 'huge', 'giant'],
    antonyms: ['small', 'tiny'],
    phrases: ['big deal', 'big city', 'a big thanks'],
  ),
  'small': FlashExtras(
    synonyms: ['little', 'tiny', 'minor'],
    antonyms: ['big', 'large'],
    phrases: ['small talk', 'a small amount', 'small steps'],
  ),
  'good': FlashExtras(
    synonyms: ['great', 'fine', 'excellent'],
    antonyms: ['bad', 'poor'],
    phrases: ['good morning', 'good luck', 'good idea'],
  ),
  'bad': FlashExtras(
    synonyms: ['poor', 'terrible', 'awful'],
    antonyms: ['good', 'great'],
    phrases: ['bad news', 'bad habit', 'not bad at all'],
  ),
  'beautiful': FlashExtras(
    synonyms: ['pretty', 'lovely', 'gorgeous'],
    antonyms: ['ugly', 'plain'],
    phrases: ['beautiful day', 'beautiful view'],
  ),
  'fast': FlashExtras(
    synonyms: ['quick', 'rapid', 'speedy'],
    antonyms: ['slow'],
    phrases: ['fast food', 'fast learner', 'hold fast'],
  ),
  'slow': FlashExtras(
    synonyms: ['gradual', 'unhurried'],
    antonyms: ['fast', 'quick'],
    phrases: ['slow down', 'slow progress'],
  ),
  'hot': FlashExtras(
    synonyms: ['warm', 'boiling'],
    antonyms: ['cold', 'cool'],
    phrases: ['hot weather', 'hot coffee', 'hot topic'],
  ),
  'cold': FlashExtras(
    synonyms: ['chilly', 'cool', 'freezing'],
    antonyms: ['hot', 'warm'],
    phrases: ['cold water', 'catch a cold', 'cold weather'],
  ),
  'easy': FlashExtras(
    synonyms: ['simple', 'effortless'],
    antonyms: ['hard', 'difficult'],
    phrases: ['take it easy', 'easy to use', 'easy going'],
  ),
  'difficult': FlashExtras(
    synonyms: ['hard', 'tough', 'challenging'],
    antonyms: ['easy', 'simple'],
    phrases: ['difficult question', 'find it difficult'],
  ),
  'important': FlashExtras(
    synonyms: ['key', 'essential', 'vital'],
    antonyms: ['minor', 'trivial'],
    phrases: ['very important', 'important person'],
  ),
  'help': FlashExtras(
    synonyms: ['assist', 'support', 'aid'],
    antonyms: ['block', 'hinder'],
    phrases: ['help me', 'ask for help', 'help each other'],
  ),
  'learn': FlashExtras(
    synonyms: ['study', 'master'],
    antonyms: ['forget', 'teach'],
    phrases: ['learn English', 'learn by heart', 'learn fast'],
  ),
  'speak': FlashExtras(
    synonyms: ['talk', 'say', 'tell'],
    antonyms: ['listen', 'stay silent'],
    phrases: ['speak up', 'speak English', 'speak slowly'],
  ),
  'listen': FlashExtras(
    synonyms: ['hear', 'pay attention'],
    antonyms: ['ignore'],
    phrases: ['listen carefully', 'listen to music'],
  ),
  'friend': FlashExtras(
    synonyms: ['mate', 'buddy', 'pal'],
    antonyms: ['enemy', 'stranger'],
    phrases: ['best friend', 'make friends', 'close friend'],
  ),
  'home': FlashExtras(
    synonyms: ['house', 'place'],
    antonyms: ['away'],
    phrases: ['at home', 'go home', 'feel at home'],
  ),
  'school': FlashExtras(
    synonyms: ['academy', 'college'],
    antonyms: [],
    phrases: ['go to school', 'after school', 'school bag'],
  ),
  'work': FlashExtras(
    synonyms: ['job', 'labour', 'task'],
    antonyms: ['rest', 'play'],
    phrases: ['go to work', 'hard work', 'work together'],
  ),
  'money': FlashExtras(
    synonyms: ['cash', 'funds'],
    antonyms: [],
    phrases: ['make money', 'save money', 'waste money'],
  ),
  'time': FlashExtras(
    synonyms: ['period', 'moment'],
    antonyms: [],
    phrases: ['on time', 'free time', 'time flies'],
  ),
  'love': FlashExtras(
    synonyms: ['adore', 'care for'],
    antonyms: ['hate', 'dislike'],
    phrases: ['fall in love', 'love you', 'love to travel'],
  ),
  'like': FlashExtras(
    synonyms: ['enjoy', 'prefer'],
    antonyms: ['hate', 'dislike'],
    phrases: ['would like', 'look like', 'feel like'],
  ),
  'want': FlashExtras(
    synonyms: ['wish', 'need'],
    antonyms: ['reject'],
    phrases: ['want to learn', 'do you want'],
  ),
  'need': FlashExtras(
    synonyms: ['require', 'must have'],
    antonyms: [],
    phrases: ['need help', 'no need', 'in need'],
  ),
  'know': FlashExtras(
    synonyms: ['understand', 'realise'],
    antonyms: ['forget'],
    phrases: ['know about', 'let me know', 'as you know'],
  ),
  'think': FlashExtras(
    synonyms: ['believe', 'consider'],
    antonyms: [],
    phrases: ['think about', 'think twice', 'I think so'],
  ),
  'understand': FlashExtras(
    synonyms: ['get', 'follow', 'grasp'],
    antonyms: ['misunderstand'],
    phrases: ['I understand', 'easy to understand'],
  ),
  'begin': FlashExtras(
    synonyms: ['start', 'open'],
    antonyms: ['end', 'finish'],
    phrases: ['begin with', 'begin again'],
  ),
  'finish': FlashExtras(
    synonyms: ['end', 'complete'],
    antonyms: ['begin', 'start'],
    phrases: ['finish work', 'finish first'],
  ),
  'buy': FlashExtras(
    synonyms: ['purchase', 'get'],
    antonyms: ['sell'],
    phrases: ['buy online', 'buy a ticket'],
  ),
  'sell': FlashExtras(
    synonyms: ['trade', 'offer'],
    antonyms: ['buy'],
    phrases: ['sell out', 'for sale'],
  ),
  'travel': FlashExtras(
    synonyms: ['journey', 'tour'],
    antonyms: ['stay'],
    phrases: ['travel abroad', 'travel light'],
  ),
  'food': FlashExtras(
    synonyms: ['meal', 'dish'],
    antonyms: [],
    phrases: ['fast food', 'healthy food', 'food court'],
  ),
  'water': FlashExtras(
    synonyms: ['liquid'],
    antonyms: [],
    phrases: ['drinking water', 'a glass of water'],
  ),
  'book': FlashExtras(
    synonyms: ['volume', 'novel'],
    antonyms: [],
    phrases: ['read a book', 'book a ticket', 'text book'],
  ),
  'computer': FlashExtras(
    synonyms: ['PC', 'machine'],
    antonyms: [],
    phrases: ['computer science', 'on the computer'],
  ),
  'phone': FlashExtras(
    synonyms: ['mobile', 'telephone'],
    antonyms: [],
    phrases: ['answer the phone', 'phone call', 'on the phone'],
  ),
  'family': FlashExtras(
    synonyms: ['relatives', 'household'],
    antonyms: [],
    phrases: ['family member', 'start a family', 'family time'],
  ),
  'teacher': FlashExtras(
    synonyms: ['tutor', 'instructor'],
    antonyms: ['student', 'pupil'],
    phrases: ['class teacher', 'English teacher'],
  ),
  'student': FlashExtras(
    synonyms: ['pupil', 'learner'],
    antonyms: ['teacher'],
    phrases: ['university student', 'good student'],
  ),
  'walk': FlashExtras(
    synonyms: ['stroll', 'step'],
    antonyms: ['run', 'drive'],
    phrases: ['go for a walk', 'walk home', 'walk fast'],
  ),
  'run': FlashExtras(
    synonyms: ['sprint', 'jog'],
    antonyms: ['walk', 'stop'],
    phrases: ['run late', 'run a business', 'run fast'],
  ),
  'eat': FlashExtras(
    synonyms: ['have', 'consume'],
    antonyms: ['fast'],
    phrases: ['eat out', 'eat healthy', 'something to eat'],
  ),
  'drink': FlashExtras(
    synonyms: ['sip', 'have'],
    antonyms: [],
    phrases: ['drink water', 'soft drink', 'something to drink'],
  ),
  'sleep': FlashExtras(
    synonyms: ['rest', 'nap'],
    antonyms: ['wake'],
    phrases: ['go to sleep', 'good sleep', 'sleep well'],
  ),
  'open': FlashExtras(
    synonyms: ['unlock', 'start'],
    antonyms: ['close', 'shut'],
    phrases: ['open the door', 'open mind', 'open air'],
  ),
  'close': FlashExtras(
    synonyms: ['shut', 'near'],
    antonyms: ['open', 'far'],
    phrases: ['close the door', 'close friend', 'close call'],
  ),
  'new': FlashExtras(
    synonyms: ['fresh', 'recent', 'modern'],
    antonyms: ['old', 'used'],
    phrases: ['brand new', 'new year', 'new job'],
  ),
  'old': FlashExtras(
    synonyms: ['aged', 'ancient'],
    antonyms: ['new', 'young'],
    phrases: ['old friend', 'years old', 'old days'],
  ),
  'young': FlashExtras(
    synonyms: ['youthful', 'little'],
    antonyms: ['old', 'adult'],
    phrases: ['young people', 'young age'],
  ),
  'strong': FlashExtras(
    synonyms: ['powerful', 'tough'],
    antonyms: ['weak'],
    phrases: ['strong coffee', 'strong opinion', 'stay strong'],
  ),
  'weak': FlashExtras(
    synonyms: ['fragile', 'faint'],
    antonyms: ['strong', 'powerful'],
    phrases: ['weak point', 'feel weak'],
  ),
  'quiet': FlashExtras(
    synonyms: ['silent', 'calm'],
    antonyms: ['loud', 'noisy'],
    phrases: ['keep quiet', 'quiet place'],
  ),
  'busy': FlashExtras(
    synonyms: ['occupied', 'hectic'],
    antonyms: ['free', 'idle'],
    phrases: ['busy day', 'too busy', 'busy street'],
  ),
  'free': FlashExtras(
    synonyms: ['open', 'costless'],
    antonyms: ['busy', 'expensive'],
    phrases: ['free time', 'for free', 'feel free'],
  ),
  'rich': FlashExtras(
    synonyms: ['wealthy', 'well-off'],
    antonyms: ['poor'],
    phrases: ['rich culture', 'get rich', 'rich taste'],
  ),
  'poor': FlashExtras(
    synonyms: ['needy', 'bad'],
    antonyms: ['rich', 'good'],
    phrases: ['poor thing', 'poor quality', 'poor family'],
  ),
  'angry': FlashExtras(
    synonyms: ['mad', 'furious'],
    antonyms: ['calm', 'happy'],
    phrases: ['get angry', 'angry with someone'],
  ),
  'afraid': FlashExtras(
    synonyms: ['scared', 'frightened'],
    antonyms: ['brave', 'calm'],
    phrases: ['afraid of', "I'm afraid so"],
  ),
  'tired': FlashExtras(
    synonyms: ['sleepy', 'exhausted'],
    antonyms: ['fresh', 'energetic'],
    phrases: ['tired of', 'feel tired', 'dead tired'],
  ),
  'hungry': FlashExtras(
    synonyms: ['starving', 'empty'],
    antonyms: ['full'],
    phrases: ['very hungry', 'hungry for success'],
  ),
  'ready': FlashExtras(
    synonyms: ['prepared', 'set'],
    antonyms: ['unprepared'],
    phrases: ['get ready', 'ready to go', 'ready for'],
  ),
  'careful': FlashExtras(
    synonyms: ['cautious', 'alert'],
    antonyms: ['careless', 'reckless'],
    phrases: ['be careful', 'careful with money'],
  ),
  'simple': FlashExtras(
    synonyms: ['easy', 'plain'],
    antonyms: ['complex', 'hard'],
    phrases: ['simple life', 'keep it simple'],
  ),
  'famous': FlashExtras(
    synonyms: ['well-known', 'popular'],
    antonyms: ['unknown'],
    phrases: ['famous for', 'world famous'],
  ),
  'dangerous': FlashExtras(
    synonyms: ['risky', 'unsafe'],
    antonyms: ['safe', 'harmless'],
    phrases: ['dangerous road', 'dangerous situation'],
  ),
  'safe': FlashExtras(
    synonyms: ['secure', 'protected'],
    antonyms: ['dangerous', 'risky'],
    phrases: ['safe place', 'stay safe', 'safe journey'],
  ),
  'weather': FlashExtras(
    synonyms: ['climate', 'conditions'],
    antonyms: [],
    phrases: ['bad weather', 'weather report', 'nice weather'],
  ),
  'study': FlashExtras(
    synonyms: ['learn', 'research'],
    antonyms: ['teach'],
    phrases: ['study hard', 'study abroad', 'case study'],
  ),
  'practice': FlashExtras(
    synonyms: ['training', 'rehearsal'],
    antonyms: [],
    phrases: ['practice makes perfect', 'speaking practice'],
  ),
  'change': FlashExtras(
    synonyms: ['alter', 'shift'],
    antonyms: ['keep', 'stay'],
    phrases: ['change your mind', 'climate change', 'small change'],
  ),
  'choose': FlashExtras(
    synonyms: ['pick', 'select'],
    antonyms: ['reject'],
    phrases: ['choose wisely', 'choose between'],
  ),
  'remember': FlashExtras(
    synonyms: ['recall', 'memorise'],
    antonyms: ['forget'],
    phrases: ['remember me', 'remember to call'],
  ),
  'forget': FlashExtras(
    synonyms: ['overlook'],
    antonyms: ['remember'],
    phrases: ['forget about it', 'never forget'],
  ),
  'believe': FlashExtras(
    synonyms: ['trust', 'think'],
    antonyms: ['doubt'],
    phrases: ['believe in yourself', 'hard to believe'],
  ),
  'dream': FlashExtras(
    synonyms: ['hope', 'ambition'],
    antonyms: ['reality'],
    phrases: ['dream big', 'dream come true', 'bad dream'],
  ),
  'success': FlashExtras(
    synonyms: ['achievement', 'win'],
    antonyms: ['failure'],
    phrases: ['big success', 'key to success'],
  ),
  'problem': FlashExtras(
    synonyms: ['issue', 'trouble'],
    antonyms: ['solution', 'answer'],
    phrases: ['no problem', 'solve a problem', 'big problem'],
  ),
  'question': FlashExtras(
    synonyms: ['query', 'doubt'],
    antonyms: ['answer'],
    phrases: ['ask a question', 'good question', 'out of the question'],
  ),
  'answer': FlashExtras(
    synonyms: ['reply', 'response'],
    antonyms: ['question'],
    phrases: ['answer the phone', 'right answer', 'answer back'],
  ),
  'idea': FlashExtras(
    synonyms: ['thought', 'plan'],
    antonyms: [],
    phrases: ['good idea', 'no idea', 'have an idea'],
  ),
  'funny': FlashExtras(
    synonyms: ['humorous', 'amusing'],
    antonyms: ['serious', 'boring'],
    phrases: ['funny story', 'funny feeling'],
  ),
  'interesting': FlashExtras(
    synonyms: ['engaging', 'exciting'],
    antonyms: ['boring', 'dull'],
    phrases: ['interesting fact', 'sound interesting'],
  ),
  'boring': FlashExtras(
    synonyms: ['dull', 'tiring'],
    antonyms: ['interesting', 'fun'],
    phrases: ['boring day', 'so boring'],
  ),
  'kind': FlashExtras(
    synonyms: ['caring', 'friendly'],
    antonyms: ['cruel', 'mean'],
    phrases: ['kind of', 'be kind', 'kind person'],
  ),
  'laugh': FlashExtras(
    synonyms: ['smile', 'giggle'],
    antonyms: ['cry'],
    phrases: ['laugh out loud', 'make me laugh'],
  ),
  'cry': FlashExtras(
    synonyms: ['weep', 'sob'],
    antonyms: ['laugh', 'smile'],
    phrases: ['cry for help', 'start to cry'],
  ),
  'smile': FlashExtras(
    synonyms: ['grin', 'beam'],
    antonyms: ['frown'],
    phrases: ['big smile', 'smile at someone'],
  ),
  'quick': FlashExtras(
    synonyms: ['fast', 'rapid'],
    antonyms: ['slow'],
    phrases: ['quick look', 'quick question', 'quickly done'],
  ),
  'clean': FlashExtras(
    synonyms: ['tidy', 'spotless'],
    antonyms: ['dirty'],
    phrases: ['clean up', 'clean water', 'keep clean'],
  ),
  'dirty': FlashExtras(
    synonyms: ['messy', 'unclean'],
    antonyms: ['clean'],
    phrases: ['dirty hands', 'dirty work'],
  ),
  'city': FlashExtras(
    synonyms: ['town', 'metropolis'],
    antonyms: ['village', 'countryside'],
    phrases: ['big city', 'city centre', 'city life'],
  ),
  'village': FlashExtras(
    synonyms: ['town', 'settlement'],
    antonyms: ['city'],
    phrases: ['small village', 'village life'],
  ),
  'morning': FlashExtras(
    synonyms: ['dawn', 'forenoon'],
    antonyms: ['evening', 'night'],
    phrases: ['good morning', 'early morning'],
  ),
  'night': FlashExtras(
    synonyms: ['evening', 'dark'],
    antonyms: ['day', 'morning'],
    phrases: ['good night', 'last night', 'all night'],
  ),
};

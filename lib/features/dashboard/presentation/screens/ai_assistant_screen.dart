import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/core/constants/app_colors.dart';
import 'package:planner/features/exams/presentation/providers/exams_provider.dart';
import 'package:planner/features/auth/presentation/providers/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _Message {
  final String text;
  final bool isUser;
  final String? actionUrl;
  final String? actionText;
  
  _Message({
    required this.text, 
    required this.isUser, 
    this.actionUrl, 
    this.actionText
  });
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_Message> _messages = [];
  bool _isTyping = false;
  final ScrollController _scrollController = ScrollController();

  // Quiz state
  bool _isInQuiz = false;
  String _currentQuizAnswer = "";
  String _currentQuizExplanation = "";

  // Pool of Quiz Questions
  final List<Map<String, dynamic>> _quizPool = [
    {
      'question': 'Quelle clause utilise-t-on en SQL pour filtrer les résultats d\'un groupe après un GROUP BY ?',
      'options': 'A) WHERE\nB) HAVING\nC) FILTER',
      'answer': 'B',
      'explanation': 'La clause HAVING est utilisée pour filtrer les groupes créés par GROUP BY. La clause WHERE filtre les lignes individuelles avant le regroupement.',
    },
    {
      'question': 'En Java, quel mot-clé permet d\'empêcher une classe d\'être héritée ?',
      'options': 'A) static\nB) abstract\nC) final',
      'answer': 'C',
      'explanation': 'Le mot-clé final appliqué à une classe empêche tout héritage de celle-ci. Si appliqué à une méthode, il empêche sa redéfinition.',
    },
    {
      'question': 'Quelle couche du modèle OSI est responsable du routage des paquets et de l\'adressage IP ?',
      'options': 'A) Couche 2 (Liaison)\nB) Couche 3 (Réseau)\nC) Couche 4 (Transport)',
      'answer': 'B',
      'explanation': 'La couche 3 (Réseau) gère l\'adressage logique (IP) et le routage des paquets à travers le réseau.',
    },
    {
      'question': 'Quelle est la complexité temporelle dans le pire des cas d\'une recherche dichotomique dans un tableau trié de taille n ?',
      'options': 'A) O(n)\nB) O(log n)\nC) O(1)',
      'answer': 'B',
      'explanation': 'La recherche dichotomique divise par 2 l\'espace de recherche à chaque étape, ce qui donne une complexité temporelle logarithmique de O(log n).',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProvider);
      final userName = user?.fullName.split(' ').first ?? '';
      
      final exams = ref.read(examsProvider);
      final upcoming = exams.where((e) => e.date.isAfter(DateTime.now())).toList();
      upcoming.sort((a, b) => a.date.compareTo(b.date));
      
      String greeting = "Bonjour${userName.isNotEmpty ? ' $userName' : ''} ! 👋\nJe suis ton Assistant d'Étude Intelligent 🤖.\n";
      
      if (upcoming.isNotEmpty) {
        final nextExam = upcoming.first;
        final formattedDate = DateFormat('dd MMM', 'fr_FR').format(nextExam.date);
        greeting += "\nJe vois que tu as un examen de ${nextExam.subject} le $formattedDate. Es-tu prêt ?\n";
      }
      
      greeting += "\nComment puis-je t'aider à préparer tes cours et tes examens aujourd'hui ? Tu peux me demander des explications ou un quiz !";
      
      greeting = greeting.replaceAll('**', '').replaceAll('*', '');

      setState(() {
        _messages.add(_Message(
          text: greeting, 
          isUser: false
        ));
      });
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _controller.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    // Simulate AI thinking time
    await Future.delayed(Duration(milliseconds: 800 + Random().nextInt(1000)));

    String reply = "";
    final lowerText = text.toLowerCase();

    // 1. If in Quiz Mode, check answer
    if (_isInQuiz) {
      final userAnswer = text.toUpperCase().trim();
      if (userAnswer == 'A' || userAnswer == 'B' || userAnswer == 'C') {
        if (userAnswer == _currentQuizAnswer) {
          reply = "Bravo ! 🎉 C'est la bonne réponse.\n\n💡 *Explication :* $_currentQuizExplanation";
        } else {
          reply = "Oups ! Ce n'est pas tout à fait ça. ❌\nLa bonne réponse était la **$_currentQuizAnswer**.\n\n💡 *Explication :* $_currentQuizExplanation";
        }
        _isInQuiz = false;
      } else {
        reply = "Veuillez répondre par **A**, **B** ou **C** pour valider votre réponse au quiz en cours !";
        // Keep quiz mode active
      }
    } 
    // 2. Trigger Quiz
    else if (lowerText.contains("quiz") || lowerText.contains("qcm") || lowerText.contains("question")) {
      final quiz = _quizPool[Random().nextInt(_quizPool.length)];
      _currentQuizAnswer = quiz['answer'];
      _currentQuizExplanation = quiz['explanation'];
      _isInQuiz = true;
      
      reply = "Voici une question de révision rapide pour vous ! 📝\n\n"
          "**Question :** ${quiz['question']}\n\n"
          "${quiz['options']}\n\n"
          "👉 *Répondez simplement en tapant A, B ou C.*";
    }
    // 3. Lessons requests
    else if (lowerText.contains("cours") || lowerText.contains("leçon") || lowerText.contains("lesson") || lowerText.contains("apprendre") || lowerText.contains("expliquer")) {
      if (lowerText.contains("sql") || lowerText.contains("base de données") || lowerText.contains("bdd")) {
        reply = "📊 **Cours : Introduction au SQL (Bases de Données)**\n\n"
            "Le SQL (Structured Query Language) permet de manipuler les bases de données relationnelles.\n\n"
            "🔑 **1. Les Commandes de Base :**\n"
            "• `SELECT` : Choisit les colonnes à afficher.\n"
            "• `FROM` : Indique la table d'origine.\n"
            "• `WHERE` : Filtre les lignes selon une condition.\n\n"
            "📝 **Exemple :**\n"
            "```sql\n"
            "SELECT nom, prenom FROM etudiants WHERE niveau = 'L3';\n"
            "```\n\n"
            "🤝 **2. Les Jointures (JOIN) :**\n"
            "Lier deux tables via une clé commune :\n"
            "```sql\n"
            "SELECT e.subject, r.name FROM exams e\n"
            "INNER JOIN rooms r ON e.room = r.name;\n"
            "```\n\n"
            "📈 **3. Regroupement (GROUP BY) :**\n"
            "Calculer des statistiques par groupe :\n"
            "```sql\n"
            "SELECT level, COUNT(*) FROM exams GROUP BY level;\n"
            "```\n\n"
            "💡 *Pratique : Tapez 'Lancer un quiz' pour tester vos connaissances !*";
      } else if (lowerText.contains("java") || lowerText.contains("dart") || lowerText.contains("programmation") || lowerText.contains("poo")) {
        reply = "☕ **Cours : La Programmation Orientée Objet (POO)**\n\n"
            "La POO est un paradigme de programmation basé sur les concepts suivants :\n\n"
            "📦 **1. L'Encapsulation :**\n"
            "Masquer les détails internes d'un objet en mettant ses attributs en `private` et en utilisant des getters/setters.\n\n"
            "🧬 **2. L'Héritage :**\n"
            "Une classe enfant hérite des attributs et méthodes d'une classe parente (mot-clé `extends` en Java / Dart).\n"
            "```dart\n"
            "class Etudiant extends Personne {\n"
            "  String niveau;\n"
            "}\n"
            "```\n\n"
            "🎭 **3. Le Polymorphisme :**\n"
            "La capacité d'une méthode à se comporter différemment (redéfinition avec `@Override`).\n\n"
            "☁️ **4. L'Abstraction :**\n"
            "Définir des modèles via des classes abstraites ou des interfaces sans écrire leur implémentation.";
      } else if (lowerText.contains("algorithme") || lowerText.contains("algo") || lowerText.contains("structure de données")) {
        reply = "💻 **Cours : Algorithmes et Complexité**\n\n"
            "Un algorithme est une suite d'instructions pour résoudre un problème.\n\n"
            "⏳ **1. La Complexité (Notation Big-O) :**\n"
            "Mesure l'efficacité d'un algorithme :\n"
            "• `O(1)` : Temps constant (accès direct).\n"
            "• `O(log n)` : Temps logarithmique (Recherche dichotomique).\n"
            "• `O(n)` : Temps linéaire (parcours simple).\n"
            "• `O(n²)` : Temps quadratique (tri à bulles).\n\n"
            "📦 **2. Structures de Données Indispensables :**\n"
            "• **Tableau (Array)** : Taille fixe, accès très rapide.\n"
            "• **Liste Chaînée** : Dynamique, insertion rapide.\n"
            "• **Pile (Stack)** : LIFO (Dernier entré, premier sorti).\n"
            "• **File (Queue)** : FIFO (Premier entré, premier sorti).\n"
            "• **Table de Hachage** : Stockage clé-valeur avec accès direct en `O(1)`.";
      } else if (lowerText.contains("réseau") || lowerText.contains("reseau") || lowerText.contains("osi") || lowerText.contains("ip")) {
        reply = "🌐 **Cours : Bases des Réseaux Informatiques**\n\n"
            "Un réseau permet l'échange de données entre terminaux.\n\n"
            "🥞 **1. Le Modèle OSI (Couches 1 à 7) :**\n"
            "1. **Physique** : Transmission des signaux physiques.\n"
            "2. **Liaison** : Adressage physique (MAC).\n"
            "3. **Réseau** : Adressage logique (IP, routage).\n"
            "4. **Transport** : Contrôle des flux (TCP, UDP).\n"
            "5. **Session** : Synchronisation des échanges.\n"
            "6. **Présentation** : Formatage et chiffrement.\n"
            "7. **Application** : Protocoles applicatifs (HTTP, DNS).\n\n"
            "🔌 **2. TCP vs UDP (Couche Transport) :**\n"
            "• **TCP** : Fiable, orienté connexion (ex: Web, Mail).\n"
            "• **UDP** : Rapide, sans connexion (ex: Vidéo en direct, Jeux).";
      } else if (lowerText.contains("pomodoro")) {
        reply = "⏱️ **La Méthode Pomodoro**\n\n"
            "Une technique de gestion du temps pour rester concentré :\n\n"
            "1️⃣ Choisir une tâche claire.\n"
            "2️⃣ Travailler sans distraction pendant **25 minutes**.\n"
            "3️⃣ Prendre une pause de **5 minutes** (s'étirer, boire de l'eau).\n"
            "4️⃣ Après **4 cycles**, s'accorder une grande pause de **15 à 30 minutes**.\n\n"
            "🚀 *Essayez de l'appliquer pour votre prochaine session d'étude !*";
      } else {
        // Dynamic Fallback Lesson Generator
        String subject = text
            .replaceAll(RegExp(r'(cours|leçon|lesson|apprendre|expliquer|sur|de|du|la|le|un|une|l\s*|d\s*|peux-tu|donne-moi|je|veux|savoir)', caseSensitive: false), '')
            .trim();
        if (subject.isEmpty) subject = "votre sujet";
        subject = subject[0].toUpperCase() + subject.substring(1);

        reply = "📚 **Guide d'Étude Spécial : $subject**\n\n"
            "Voici un cours structuré pour vous aider à réviser **$subject** :\n\n"
            "🔍 **1. Concepts Fondamentaux :**\n"
            "• **Introduction** : Comprendre les bases et l'importance de cette notion.\n"
            "• **Principes clés** : Les règles, formules ou définitions essentielles.\n"
            "• **Vocabulaire** : Les termes incontournables à retenir pour l'examen.\n\n"
            "⚡ **2. Méthode de Révision Conseillée :**\n"
            "• **Feynman Technique** : Essayez d'expliquer ce concept de $subject avec des mots très simples à un ami.\n"
            "• **Rappel Actif** : Cachez vos notes et écrivez tout ce que vous avez retenu sur ce sujet.\n\n"
            "📝 **3. Question d'Auto-Évaluation :**\n"
            "Selon vous, quelle est l'application la plus concrète de **$subject** dans la vie réelle ou dans vos projets ? Prenez 2 minutes pour y réfléchir !";
      }
    }
    // 4. YouTube / Internet search dynamic intent
    else if (lowerText.contains("youtube") || lowerText.contains("vidéo") || lowerText.contains("video") || lowerText.contains("internet") || lowerText.contains("chercher") || lowerText.contains("lien")) {
      String query = text.replaceAll(RegExp(r'(cherche|sur|internet|youtube|vidéo|video|lien|pour|etudier|apprendre|un|une|le|la|les|des|de|peux-tu|donne-moi|je|veux|savoir)', caseSensitive: false), '').trim();
      if (query.isEmpty) query = "tutoriel";
      
      final isYoutube = lowerText.contains("youtube") || lowerText.contains("vidéo") || lowerText.contains("video");
      final url = isYoutube 
          ? "https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}"
          : "https://www.google.com/search?q=${Uri.encodeComponent(query)}";
          
      reply = "Bien sûr ! J'ai trouvé ce qu'il vous faut. Voici un lien direct pour étudier **$query** :\n\nCliquez sur le bouton ci-dessous pour y accéder immédiatement :";
      
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(_Message(
            text: reply, 
            isUser: false,
            actionText: isYoutube ? 'Ouvrir sur YouTube' : 'Chercher sur Internet',
            actionUrl: url,
          ));
        });
        _scrollToBottom();
      }
      return;
    }
    // 5. Next Exam request
    else if (lowerText.contains("examen") || lowerText.contains("prochain")) {
      final allExams = ref.read(examsProvider);
      final now = DateTime.now();
      final upcomingExams = allExams.where((e) => e.date.isAfter(now.subtract(const Duration(hours: 12)))).toList();
      upcomingExams.sort((a, b) => a.date.compareTo(b.date));

      if (upcomingExams.isEmpty) {
        reply = "Vous n'avez aucun examen de prévu pour le moment. Profitez-en pour vous reposer ! 😌";
      } else {
        final next = upcomingExams.first;
        reply = "Votre prochain examen est **${next.subject}** le ${next.date.day}/${next.date.month} à ${next.time} en salle ${next.room}. Je vous conseille de commencer à réviser avec la méthode Pomodoro !";
      }
    } 
    // 6. Tips/Advice
    else if (lowerText.contains("conseil") || lowerText.contains("astuce") || lowerText.contains("aider")) {
      final tips = [
        "Astuce : Essayez la technique du 'Rappel Actif'. Fermez vos cours et essayez de tout réécrire de mémoire !",
        "Un bon sommeil est crucial avant un examen. Essayez de dormir au moins 8h la veille.",
        "Si vous bloquez sur un concept, essayez de l'expliquer à voix haute comme si vous étiez le prof (Technique de Feynman) !",
        "Divisez votre travail : étudiez par blocs de 25 minutes (Pomodoro) avec 5 minutes de pause."
      ];
      reply = tips[Random().nextInt(tips.length)];
    } 
    // 7. Generic response
    else {
      reply = "Je suis là pour vous aider dans vos études ! 🎓\n\n"
          "Vous pouvez me demander :\n"
          "• Un **cours** (ex: *'donne-moi un cours de SQL'*)\n"
          "• Une **vidéo YouTube** (*'cherche une vidéo YouTube sur Java'*)\n"
          "• Lancer un **quiz** (*'lance un quiz'*)\n"
          "• Vos **examens** à venir (*'prochain examen ?'*)\n"
          "• Des **conseils de révision**";
    }

    if (mounted) {
      setState(() {
        _isTyping = false;
        reply = reply.replaceAll('**', '').replaceAll('*', '');
        _messages.add(_Message(text: reply, isUser: false));
      });
      _scrollToBottom();
    }
  }

  Widget _buildSuggestions() {
    final suggestions = [
      '📚 Cours de SQL',
      '💻 Cours d\'Algorithme',
      '☕ Cours de Java',
      '🌐 Cours de Réseaux',
      '⏱️ Méthode Pomodoro',
      '📝 Lancer un Quiz',
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                suggestion,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                if (suggestion.contains("Quiz")) {
                  _controller.text = "Lancer un quiz";
                } else if (suggestion.contains("Pomodoro")) {
                  _controller.text = "Explique-moi la méthode Pomodoro";
                } else {
                  _controller.text = "Peux-tu me donner un cours sur : ${suggestion.substring(2)} ?";
                }
                _sendMessage();
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Assistant IA',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          _buildSuggestions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_Message msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(msg.isUser ? 24 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isUser ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (msg.actionUrl != null && msg.actionText != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(msg.actionUrl!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: Icon(
                  msg.actionUrl!.contains('youtube') ? Icons.play_circle_fill_rounded : Icons.language_rounded, 
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(msg.actionText!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: msg.actionUrl!.contains('youtube') ? Colors.red.shade600 : AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedDot(delay: 0),
            const SizedBox(width: 4),
            _AnimatedDot(delay: 200),
            const SizedBox(width: 4),
            _AnimatedDot(delay: 400),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Posez une question...',
                hintStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  final int delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -5 * _animation.value),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

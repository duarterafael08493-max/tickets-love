import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

const adminUid = 'VruRcSStqMW52Po1QhK7jANyAwD2';
const blush = Color(0xFF3A101B);
const rose = Color(0xFFFF315B);
const ink = Color(0xFFFFF1F4);
const muted = Color(0xFFC6AAB1);
const backgroundDark = Color(0xFF100509);
const surfaceDark = Color(0xFF210B12);
const surfaceRaised = Color(0xFF32101B);
const neonRose = Color(0xFFFF6685);

final db = FirebaseFirestore.instance;
final auth = FirebaseAuth.instance;
final localNotifications = FlutterLocalNotificationsPlugin();

Future<void> initializeLocalNotifications() async {
  if (kIsWeb) return;
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: android);
await localNotifications.initialize(
  settings: settings,
);  final androidPlugin = localNotifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.requestNotificationsPermission();
}

Future<void> showLocalNotification({required int id, required String title, required String body}) async {
  if (kIsWeb) return;
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'tickets_love_updates',
      'Atualizações do Tickets Love',
      channelDescription: 'Avisos de resgates e missões enviados pela sua namorada.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    ),
  );
 await localNotifications.show(
  id: id,
  title: title,
  body: body,
  notificationDetails: details,
);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeLocalNotifications();
  runApp(const TicketsLoveApp());
}

class TicketsLoveApp extends StatelessWidget {
  const TicketsLoveApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Tickets Love ❤️',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: backgroundDark,
          colorScheme: const ColorScheme.dark(
            primary: rose,
            secondary: neonRose,
            surface: surfaceDark,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: ink,
            error: Color(0xFFFF6677),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: backgroundDark,
            foregroundColor: ink,
            elevation: 0,
            centerTitle: false,
          ),
          cardTheme: CardThemeData(
            color: surfaceDark,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF54202E)),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFF19070D),
            indicatorColor: const Color(0xFF5A1428),
            iconTheme: WidgetStateProperty.resolveWith((states) =>
              IconThemeData(color: states.contains(WidgetState.selected)
                ? rose : muted)),
            labelTextStyle: WidgetStateProperty.resolveWith((states) =>
              TextStyle(fontSize: 11, color: states.contains(WidgetState.selected)
                ? rose : muted, fontWeight: FontWeight.w600)),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: rose,
            foregroundColor: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: surfaceRaised,
            labelStyle: const TextStyle(color: muted),
            prefixIconColor: neonRose,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF713044)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF54202E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: rose, width: 1.5),
            ),
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: surfaceDark,
            titleTextStyle: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.bold),
            contentTextStyle: TextStyle(color: muted),
          ),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: surfaceRaised,
            contentTextStyle: TextStyle(color: ink),
          ),
          textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: ink,
            displayColor: ink,
          ),
        ),
        home: const AuthGate(),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: rose)),
            );
          }
          final user = snapshot.data;
          if (user == null) return const LoginPage();
          return HomePage(isAdmin: user.uid == adminUid);
        },
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool creating = false;
  bool busy = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void showMessage(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> submit() async {
    final e = email.text.trim();
    final p = password.text;
    if (e.isEmpty || p.length < 6) {
      showMessage('Informe o e-mail e uma senha com pelo menos 6 caracteres.');
      return;
    }
    setState(() => busy = true);
    try {
      if (creating) {
        await auth.createUserWithEmailAndPassword(email: e, password: p);
      } else {
        await auth.signInWithEmailAndPassword(email: e, password: p);
      }
    } on FirebaseAuthException catch (error) {
      final message = switch (error.code) {
        'invalid-email' => 'E-mail inválido.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'E-mail ou senha incorretos.',
        'email-already-in-use' => 'Esse e-mail já está cadastrado.',
        'weak-password' => 'A senha precisa ter pelo menos 6 caracteres.',
        'too-many-requests' => 'Muitas tentativas. Aguarde e tente novamente.',
        _ => error.message ?? 'Não foi possível entrar.',
      };
      showMessage(message);
    } catch (_) {
      showMessage('Falha de conexão com o Firebase.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: [
                    Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(38),
                        border: Border.all(color: rose, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66FF315B), blurRadius: 28, spreadRadius: 2),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/tickets_love_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tickets Love ❤️',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aqui você pode resgatar tickets de carinho e completar missões para conquistar recompensas especiais.',
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 38),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        creating ? 'Criar conta' : 'Entrar na sua conta',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      onSubmitted: (_) => busy ? null : submit(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 239, 239, 239),
                          foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                        ),
                        onPressed: busy ? null : submit,
                        child: busy
                            ? const CircularProgressIndicator(
                                color: surfaceDark,
                              )
                            : Text(creating ? 'Criar conta' : 'Entrar'),
                      ),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() => creating = !creating),
                      child: Text(
                        creating
                            ? 'Já tenho conta. Fazer login'
                            : 'Criar uma nova conta',
                        style: const TextStyle(color: rose),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.isAdmin});
  final bool isAdmin;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _redemptionListener;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _missionListener;
  bool _redemptionsPrimed = false;
  bool _missionsPrimed = false;

  @override
  void initState() {
    super.initState();
    if (widget.isAdmin) {
      _redemptionListener = db.collection('redemptions')
          .where('status', isEqualTo: 'pending').snapshots().listen((snapshot) {
        if (!_redemptionsPrimed) {
          _redemptionsPrimed = true;
          return;
        }
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            showLocalNotification(
              id: change.doc.id.hashCode,
              title: 'Novo resgate! ❤️',
              body: '${data?['email'] ?? 'Sua namorada'} solicitou um ticket.',
            );
          }
        }
      });
      _missionListener = db.collection('mission_submissions')
          .where('status', isEqualTo: 'pending').snapshots().listen((snapshot) {
        if (!_missionsPrimed) {
          _missionsPrimed = true;
          return;
        }
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            showLocalNotification(
              id: change.doc.id.hashCode,
              title: 'Missão concluída! 💗',
              body: '${data?['email'] ?? 'Sua namorada'} enviou uma missão para aprovação.',
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _redemptionListener?.cancel();
    _missionListener?.cancel();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> get tickets =>
      db.collection('tickets');
  CollectionReference<Map<String, dynamic>> get missions =>
      db.collection('missions');
  CollectionReference<Map<String, dynamic>> get redemptions =>
      db.collection('redemptions');
  CollectionReference<Map<String, dynamic>> get submissions =>
      db.collection('mission_submissions');

  void message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> saveTicket({
    String? id,
    required String title,
    required String description,
    required String emoji,
    required int color,
  }) async {
    final values = {
      'title': title,
      'description': description,
      'emoji': emoji,
      'color': color,
    };
    if (id == null) {
      await tickets.add({
        ...values,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await tickets.doc(id).update(values);
    }
  }

  Future<void> editTicket({DocumentSnapshot? doc}) async {
    final old = doc?.data() as Map<String, dynamic>?;
    final title = TextEditingController(text: old?['title'] ?? '');
    final description =
        TextEditingController(text: old?['description'] ?? '');
    String emoji = old?['emoji'] ?? '♡';
    int color = (old?['color'] as num?)?.toInt() ?? 0xFF4A1424;
    const emojis = ['♡', '💌', '🎁', '🍝', '🎬', '🌷', '✨', '☕'];
    const colors = [
      0xFF4A1424,
      0xFF251A35,
      0xFF173329,
      0xFF3B2B17,
      0xFF30203F,
    ];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: Text(doc == null ? 'Novo ticket' : 'Editar ticket'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Nome da recompensa',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Símbolo'),
                ),
                Wrap(
                  spacing: 6,
                  children: emojis
                      .map((item) => ChoiceChip(
                            label: Text(item),
                            selected: emoji == item,
                            onSelected: (_) => refresh(() => emoji = item),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Cor'),
                ),
                Wrap(
                  spacing: 10,
                  children: colors
                      .map((item) => InkWell(
                            onTap: () => refresh(() => color = item),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Color(item),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: color == item ? rose : Colors.black12,
                                  width: color == item ? 3 : 1,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().isEmpty) return;
                try {
                  await saveTicket(
                    id: doc?.id,
                    title: title.text.trim(),
                    description: description.text.trim().isEmpty
                        ? 'Uma recompensa especial.'
                        : description.text.trim(),
                    emoji: emoji,
                    color: color,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (_) {
                  message('Não foi possível salvar o ticket.');
                }
              },
              child: Text(doc == null ? 'Criar ticket' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    description.dispose();
  }

  Future<void> deleteTicket(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir ticket?'),
        content: Text('Deseja realmente excluir "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await tickets.doc(id).delete();
      } catch (_) {
        message('Não foi possível excluir.');
      }
    }
  }

  Future<void> redeem(String ticketId) async {
    final uid = auth.currentUser!.uid;
    try {
      final existing = await redemptions
          .where('ticketId', isEqualTo: ticketId)
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();
      if (existing.docs.isNotEmpty) {
        message('Você já solicitou esse ticket.');
        return;
      }
      await redemptions.add({
        'ticketId': ticketId,
        'userId': uid,
        'email': auth.currentUser?.email ?? 'E-mail não informado',
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });
      message('Pedido de resgate enviado!');
    } catch (_) {
      message('Não foi possível solicitar o resgate.');
    }
  }

  Future<void> approveRedemption(String requestId, String ticketId) async {
    try {
      final batch = db.batch();
      batch.update(redemptions.doc(requestId), {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      batch.update(tickets.doc(ticketId), {
        'status': 'used',
        'usedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      message('Resgate confirmado!');
    } catch (_) {
      message('Falha ao confirmar o resgate.');
    }
  }

  Future<void> addMission() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova missão'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Descrição'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty) {
      try {
        await missions.add({
          'title': value,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        message('Não foi possível criar a missão.');
      }
    }
  }

  Future<void> submitMission(String missionId) async {
    final uid = auth.currentUser!.uid;
    try {
      final existing = await submissions
          .where('missionId', isEqualTo: missionId)
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();
      if (existing.docs.isNotEmpty) {
        message('Essa missão já está aguardando aprovação.');
        return;
      }
      await submissions.add({
        'missionId': missionId,
        'userId': uid,
        'email': auth.currentUser?.email ?? 'E-mail não informado',
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });
      message('Missão enviada para aprovação!');
    } catch (_) {
      message('Não foi possível enviar a missão.');
    }
  }

  Future<void> reviewMission(String id, bool approve) async {
    try {
      await submissions.doc(id).update({
        'status': approve ? 'approved' : 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      message(approve ? 'Missão aprovada!' : 'Missão recusada.');
    } catch (_) {
      message('Não foi possível atualizar a missão.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.isAdmin
        ? [adminTicketsPage(), adminMissionsPage(), redemptionPage()]
        : [walletPage(), missionsPage(), historyPage()];
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tickets Love ❤️',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              widget.isAdmin
                  ? 'Painel do administrador'
                  : 'Sua carteira de carinho',
              style: const TextStyle(fontSize: 11, color: muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(child: pages[tab]),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: tab == 0 ? () => editTicket() : addMission,
              backgroundColor: rose,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(tab == 0 ? 'Novo ticket' : 'Nova missão'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: widget.isAdmin
            ? const [
                NavigationDestination(
                  icon: Icon(Icons.confirmation_number_outlined),
                  label: 'Tickets',
                ),
                NavigationDestination(
                  icon: Icon(Icons.flag_outlined),
                  label: 'Missões',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_none),
                  label: 'Resgates',
                ),
              ]
            : const [
                NavigationDestination(
                  icon: Icon(Icons.wallet_outlined),
                  label: 'Carteira',
                ),
                NavigationDestination(
                  icon: Icon(Icons.flag_outlined),
                  label: 'Missões',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history),
                  label: 'Histórico',
                ),
              ],
      ),
    );
  }

  Widget header(String title, String subtitle) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: neonRose,
              ),
            ),
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(color: muted, fontSize: 13)),
          ],
        ),
      );

  Widget loader() =>
      const Center(child: CircularProgressIndicator(color: rose));

  Widget failure() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Não foi possível carregar os dados. Confira sua conexão e as regras do Firestore.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted),
          ),
        ),
      );

  Widget walletPage() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: tickets.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, ticketSnap) {
          if (ticketSnap.hasError) return failure();
          if (!ticketSnap.hasData) return loader();
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: redemptions
                .where('userId', isEqualTo: auth.currentUser!.uid)
                .snapshots(),
            builder: (context, requestSnap) {
              if (requestSnap.hasError) return failure();
              if (!requestSnap.hasData) return loader();
              final blocked = requestSnap.data!.docs
                  .where((d) =>
                      d.data()['status'] == 'pending' ||
                      d.data()['status'] == 'approved')
                  .map((d) => d.data()['ticketId'] as String)
                  .toSet();
              final available = ticketSnap.data!.docs
                  .where((d) =>
                      d.data()['status'] != 'used' && !blocked.contains(d.id))
                  .toList();
              return ListView(
                children: [
                  header('Oi, minha bubu', 'Tem carinho esperando por você.'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: blush,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Cada ticket guarda um momento especial.',
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                          ),
                          Text(
                            '${available.length}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: rose,
                            ),
                          ),
                          const Text(
                            ' disponíveis',
                            style: TextStyle(fontSize: 11, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: Text(
                      'Seus tickets',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ...available.map((d) => ticketCard(d, false)),
                  if (available.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Sua carteira está vazia. Novos tickets aparecerão aqui!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: muted),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      );

  Widget adminTicketsPage() =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: tickets.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return failure();
          if (!snap.hasData) return loader();
          return ListView(
            children: [
              header('Seus tickets', 'Crie recompensas para entregar a ela.'),
              ...snap.data!.docs.map((d) => ticketCard(d, true)),
              if (snap.data!.docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Nenhum ticket criado ainda. Use “Novo ticket” para começar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted),
                    ),
                  ),
                ),
            ],
          );
        },
      );

  Widget ticketCard(
    DocumentSnapshot<Map<String, dynamic>> doc,
    bool admin,
  ) {
    final data = doc.data()!;
    final used = data['status'] == 'used';
    final color = (data['color'] as num?)?.toInt() ?? 0xFF4A1424;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 7, 20, 7),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF54202E)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(color),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      data['emoji'] ?? '♡',
                      style: const TextStyle(fontSize: 23),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Ticket',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['description'] ?? '',
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0ECEE)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
            child: Row(
              children: [
                Text(
                  used ? 'Utilizado' : 'Disponível',
                  style: TextStyle(
                    color: used ? muted : rose,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (!admin && !used)
                  TextButton(
                    onPressed: () => redeem(doc.id),
                    child: const Text('Resgatar'),
                  ),
                if (admin && !used) ...[
                  IconButton(
                    onPressed: () => editTicket(doc: doc),
                    icon: const Icon(Icons.edit_outlined, size: 19),
                  ),
                  IconButton(
                    onPressed: () => deleteTicket(doc.id, data['title'] ?? ''),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 19,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget missionsPage() =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: missions.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return failure();
          if (!snap.hasData) return loader();
          return ListView(
            children: [
              header('Missões', 'Complete uma missão para conquistar recompensas.'),
              ...snap.data!.docs.map((mission) => Container(
                    margin: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: surfaceDark,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF54202E)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flag_outlined, color: rose),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            mission.data()['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ink,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => submitMission(mission.id),
                          child: const Text('Concluir'),
                        ),
                      ],
                    ),
                  )),
              if (snap.data!.docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Nenhuma missão cadastrada ainda.',
                      style: TextStyle(color: muted),
                    ),
                  ),
                ),
            ],
          );
        },
      );

  Widget adminMissionsPage() =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: submissions
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return failure();
          if (!snap.hasData) return loader();
          return ListView(
            children: [
              header('Missões', 'Solicitações aguardando sua aprovação.'),
              ...snap.data!.docs.map((submission) => Container(
                    margin: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceDark,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF54202E)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          future: missions.doc(submission.data()['missionId']).get(),
                          builder: (context, missionSnap) {
                            final missionTitle = missionSnap.data?.data()?['title'] ??
                                'Missão enviada';
                            return Text(
                              missionTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: ink,
                                fontSize: 15,
                              ),
                            );
                          },
                        ),
                        Text(
                          'Enviada por: ${submission.data()['email'] ?? 'Conta da namorada'}',
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          submission.data()['submittedAt'] is Timestamp
                              ? 'Em ${(submission.data()['submittedAt'] as Timestamp).toDate().toLocal()}'
                              : 'Envio recente',
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  reviewMission(submission.id, false),
                              child: const Text('Recusar'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  reviewMission(submission.id, true),
                              child: const Text('Aprovar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
              if (snap.data!.docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Nenhuma missão aguardando aprovação.',
                      style: TextStyle(color: muted),
                    ),
                  ),
                ),
              const Divider(),
              header('Todas as missões', 'Desafios disponíveis no aplicativo.'),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: missions.snapshots(),
                builder: (context, missionSnap) {
                  if (!missionSnap.hasData) return loader();
                  return Column(
                    children: missionSnap.data!.docs
                        .map((m) => ListTile(
                              title: Text(m.data()['title'] ?? ''),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => missions.doc(m.id).delete(),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      );

  Widget redemptionPage() =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: redemptions
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return failure();
          if (!snap.hasData) return loader();
          return ListView(
            children: [
              header('Resgates', 'Pedidos aguardando sua confirmação.'),
              ...snap.data!.docs.map((request) => FutureBuilder<
                      DocumentSnapshot<Map<String, dynamic>>>(
                    future: tickets.doc(request.data()['ticketId']).get(),
                    builder: (context, ticketSnap) {
                      if (!ticketSnap.hasData || !ticketSnap.data!.exists) {
                        return const SizedBox.shrink();
                      }
                      final ticket = ticketSnap.data!;
                      return Container(
                        margin: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceDark,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF54202E)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.data()?['title'] ?? 'Ticket',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: ink,
                              ),
                            ),
                            Text(
                              'Solicitado por: ${request.data()['email'] ?? 'Conta da namorada'}',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: () => approveRedemption(
                                  request.id,
                                  ticket.id,
                                ),
                                child: const Text('Confirmar resgate'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )),
              if (snap.data!.docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Nenhum resgate pendente por enquanto.',
                      style: TextStyle(color: muted),
                    ),
                  ),
                ),
            ],
          );
        },
      );

  Widget historyPage() =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: tickets
            .where('status', isEqualTo: 'used')
            .orderBy('usedAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return failure();
          if (!snap.hasData) return loader();
          return ListView(
            children: [
              header('Histórico', 'Aqui ficam os tickets já utilizados.'),
              ...snap.data!.docs.map((d) => ticketCard(d, false)),
              if (snap.data!.docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Nenhum ticket utilizado ainda.',
                      style: TextStyle(color: muted),
                    ),
                  ),
                ),
            ],
          );
        },
      );
}

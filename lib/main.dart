import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String baseUrl = "http://mamaisonronchamp.duckdns.org:7941";
  final String localIP = "http://192.168.1.79";
  final String externalIP = "http://mamaisonronchamp.ddns.net:7941";

  bool portailFerme = true;
  bool portillonFerme = true;
  bool garageFerme = true;

  bool blinkPortail = false;
  bool blinkPortillon = false;
  bool blinkGarage = false;

  bool isConnected = false;
  String lastActionMessage = "Aucune action";

  Timer? actionTimer;

  @override
  void initState() {
    super.initState();

    getStatus();

    Timer.periodic(const Duration(seconds: 3), (_) {
      getStatus();
    });
  }

  @override
  void dispose() {
    actionTimer?.cancel();
    super.dispose();
  }

  // 🔥 AUTO SWITCH WIFI / 4G
  Future<String> getWorkingUrl() async {
    try {
      final res = await http
          .get(Uri.parse("$localIP/status"))
          .timeout(const Duration(seconds: 1));

      if (res.statusCode == 200) {
        print("👉 LOCAL OK");
        return localIP;
      }
    } catch (_) {}

    print("👉 EXTERNE OK");
    return externalIP;
  }

  // 🚀 ENVOI COMMANDE
  Future<void> sendCommand(String cmd) async {
    final url = await getWorkingUrl();

    try {
      final res = await http
          .get(Uri.parse("$url/$cmd"))
          .timeout(const Duration(seconds: 5));

      print("CMD => ${res.body}");

      setState(() {
        lastActionMessage = "Commande \"$cmd\" envoyée";
        isConnected = true;
      });

      triggerBlink(cmd);

      actionTimer?.cancel();
      actionTimer = Timer(const Duration(seconds: 10), () {
        setState(() => lastActionMessage = "Aucune action");
      });

    } catch (e) {
      print("ERREUR CMD => $e");

      setState(() {
        lastActionMessage = "Erreur réseau";
        isConnected = false;
      });
    }
  }

  // 📡 STATUS
  Future<void> getStatus() async {
    final url = await getWorkingUrl();

    try {
      final res = await http
          .get(Uri.parse("$url/status"))
          .timeout(const Duration(seconds: 5));

      print("STATUS => ${res.body}");

      final data = res.body.split(",");

      if (data.length == 3) {
        setState(() {
          portailFerme = data[0] == "1";
          portillonFerme = data[1] == "1";
          garageFerme = data[2] == "1";
          isConnected = true;
        });
      }
    } catch (e) {
      print("ERREUR STATUS => $e");

      setState(() {
        isConnected = false;
      });
    }
  }

  // 🔥 BLINK
  void triggerBlink(String cmd) {
    int count = 0;
    int maxCount = 20;

    if (cmd == "portail") maxCount = 50;
    if (cmd == "portillon") maxCount = 10;
    if (cmd == "garage") maxCount = 34;

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        if (cmd == "portail") blinkPortail = !blinkPortail;
        if (cmd == "portillon") blinkPortillon = !blinkPortillon;
        if (cmd == "garage") blinkGarage = !blinkGarage;
      });

      count++;

      if (count >= maxCount) {
        timer.cancel();
        setState(() {
          blinkPortail = false;
          blinkPortillon = false;
          blinkGarage = false;
        });
      }
    });
  }

  Widget statusBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            isConnected
                ? "Connexion avec la maison RÉUSSIE"
                : "Connexion avec la maison ÉCHOUÉE",
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            lastActionMessage,
            style: const TextStyle(color: Colors.black),
          )
        ],
      ),
    );
  }

  Widget card(
    String title,
    bool isOpen,
    String subtitle,
    String imagePath,
    Color color,
    String cmd,
    bool blink,
    String label,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.35),
                  Colors.black.withOpacity(0.5),
                ],
              ),
              border: Border.all(color: color.withOpacity(0.6)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 1.0,
                        end: blink ? 0.2 : 1.0,
                      ),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return Opacity(opacity: value, child: child);
                      },
                      child: Container(
                        width: 150,
                        height: 110,
                        alignment: Alignment.center,
                        child: Transform.scale(
                          scaleX: 1.3,
                          child: Image.asset(imagePath),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isOpen ? Icons.lock_open : Icons.lock,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(title,
                                style: const TextStyle(fontSize: 22)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? Colors.green
                                    : Colors.orangeAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(isOpen ? "Ouvert" : "Fermé"),
                          ],
                        ),
                        Text(subtitle,
                            style:
                                const TextStyle(color: Colors.white54)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 25),
                AnimatedButton(
                  onTap: () => sendCommand(cmd),
                  color: color,
                  label: label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: isConnected
          ? const Color(0xFF0F172A)
          : const Color(0xFF1A0A0A),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                statusBar(),
                Expanded(
                  child: ListView(
                    children: [
                      card("Portail", !portailFerme, "Accès principal",
                          "assets/icons/portail.png",
                          Colors.greenAccent, "portail", blinkPortail, "Ouvrir / Fermer"),
                      card("Portillon", !portillonFerme, "Accès piéton",
                          "assets/icons/portillon.png",
                          Colors.orangeAccent, "portillon", blinkPortillon, "Ouvrir"),
                      card("Garage", !garageFerme, "Garage",
                          "assets/icons/garage.png",
                          Colors.blueAccent, "garage", blinkGarage, "Ouvrir / Fermer"),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🔥 SLIDER
class AnimatedButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color color;
  final String label;

  const AnimatedButton({
    super.key,
    required this.onTap,
    required this.color,
    required this.label,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  double position = 0;
  bool validated = false;

  void reset() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        validated = false;
        position = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width - 147;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        color: widget.color.withOpacity(0.25),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: validated
                  ? const Icon(Icons.check, color: Colors.white)
                  : Text(widget.label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            left: position,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (validated) return;
                setState(() {
                  position += details.delta.dx;
                  position = position.clamp(0, maxWidth);
                });
              },
              onHorizontalDragEnd: (_) {
                if (position > maxWidth * 0.7) {
                  setState(() {
                    position = maxWidth;
                    validated = true;
                  });

                  widget.onTap();
                  HapticFeedback.mediumImpact();
                  reset();
                } else {
                  setState(() => position = 0);
                }
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
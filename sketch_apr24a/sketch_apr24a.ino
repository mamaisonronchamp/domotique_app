#include <WiFi.h>
#include <WebServer.h>

// WIFI
const char* ssid = "SFR_1F50";
const char* password = "pus28urzq7fwj94uxpp9";

WebServer server(80);

// =======================
// RELAIS
// =======================
#define RELAIS_PORTAIL 23
#define RELAIS_PORTILLON 22
#define RELAIS_GARAGE 21

// =======================
// CAPTEURS (1 = fermé)
// =======================
#define CAPTEUR_PORTAIL 34
#define CAPTEUR_PORTILLON 35
#define CAPTEUR_GARAGE 32

// =======================
// BOUTONS LOCAUX
// =======================
#define BTN_PORTAIL_LOCAL 18
#define BTN_PORTILLON_LOCAL 19
#define BTN_GARAGE_LOCAL 5

// =======================
// BOUTONS DISTANTS
// =======================
#define BTN_PORTAIL_DIST 17
#define BTN_PORTILLON_DIST 16
#define BTN_GARAGE_DIST 4

// =======================
// ANTI-REBOND
// =======================
unsigned long lastPress[6] = {0,0,0,0,0,0};
const int debounceDelay = 300;

// =======================
// IMPULSION RELAIS
// =======================
void pulseRelay(int pin) {
  digitalWrite(pin, HIGH);
  delay(500); // impulsion
  digitalWrite(pin, LOW);
}

// =======================
// ACTIONS CENTRALISÉES
// =======================
void triggerPortail() {
  pulseRelay(RELAIS_PORTAIL);
}

void triggerPortillon() {
  pulseRelay(RELAIS_PORTILLON);
}

void triggerGarage() {
  pulseRelay(RELAIS_GARAGE);
}

// =======================
// HTTP ROUTES
// =======================
void handlePortail() {
  triggerPortail();
  server.send(200, "text/plain", "OK");
}

void handlePortillon() {
  triggerPortillon();
  server.send(200, "text/plain", "OK");
}

void handleGarage() {
  triggerGarage();
  server.send(200, "text/plain", "OK");
}

// FORMAT : 1,0,1
void handleStatus() {
  int portail = digitalRead(CAPTEUR_PORTAIL);
  int portillon = digitalRead(CAPTEUR_PORTILLON);
  int garage = digitalRead(CAPTEUR_GARAGE);

  String status = String(portail) + "," +
                  String(portillon) + "," +
                  String(garage);

  server.send(200, "text/plain", status);
}

// =======================
// GESTION BOUTON
// =======================
bool checkButton(int pin, int index) {
  if (digitalRead(pin) == LOW) { // appui
    if (millis() - lastPress[index] > debounceDelay) {
      lastPress[index] = millis();
      return true;
    }
  }
  return false;
}

// =======================
// SETUP
// =======================
void setup() {
  Serial.begin(115200);

  // RELAIS
  pinMode(RELAIS_PORTAIL, OUTPUT);
  pinMode(RELAIS_PORTILLON, OUTPUT);
  pinMode(RELAIS_GARAGE, OUTPUT);

  digitalWrite(RELAIS_PORTAIL, LOW);
  digitalWrite(RELAIS_PORTILLON, LOW);
  digitalWrite(RELAIS_GARAGE, LOW);

  // CAPTEURS
  pinMode(CAPTEUR_PORTAIL, INPUT);
  pinMode(CAPTEUR_PORTILLON, INPUT);
  pinMode(CAPTEUR_GARAGE, INPUT);

  // BOUTONS (INPUT_PULLUP)
  pinMode(BTN_PORTAIL_LOCAL, INPUT_PULLUP);
  pinMode(BTN_PORTILLON_LOCAL, INPUT_PULLUP);
  pinMode(BTN_GARAGE_LOCAL, INPUT_PULLUP);

  pinMode(BTN_PORTAIL_DIST, INPUT_PULLUP);
  pinMode(BTN_PORTILLON_DIST, INPUT_PULLUP);
  pinMode(BTN_GARAGE_DIST, INPUT_PULLUP);

  // WIFI
  WiFi.begin(ssid, password);

  Serial.print("Connexion WiFi...");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nConnecté !");
  Serial.print("IP : ");
  Serial.println(WiFi.localIP());

  // ROUTES
  server.on("/portail", handlePortail);
  server.on("/portillon", handlePortillon);
  server.on("/garage", handleGarage);
  server.on("/status", handleStatus);

  server.begin();
  Serial.println("Serveur HTTP démarré");
}

// =======================
// LOOP
// =======================
void loop() {
  server.handleClient();

  // PORTAIL
  if (checkButton(BTN_PORTAIL_LOCAL, 0) ||
      checkButton(BTN_PORTAIL_DIST, 1)) {
    triggerPortail();
  }

  // PORTILLON
  if (checkButton(BTN_PORTILLON_LOCAL, 2) ||
      checkButton(BTN_PORTILLON_DIST, 3)) {
    triggerPortillon();
  }

  // GARAGE
  if (checkButton(BTN_GARAGE_LOCAL, 4) ||
      checkButton(BTN_GARAGE_DIST, 5)) {
    triggerGarage();
  }
}
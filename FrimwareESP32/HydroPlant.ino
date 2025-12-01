/* Smart Plant Watering System 
   FIX: Solusi untuk Relay 5V yang tidak mau mati (Stuck ON) pada ESP32.
   Metode: Open Drain Simulation (Manipulasi pinMode)
*/

#include <WiFi.h>
#include <PubSubClient.h>
#include <LiquidCrystal_I2C.h>
#include <WiFiManager.h>

// --- Konfigurasi MQTT ---
const char* mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;
const char* mqtt_client_id = "ESP32PlantWaterer_HydroPlant_Fix"; 

const char* topic_moisture_publish = "plant/moisture";
const char* topic_pump_subscribe = "plant/pump/control";

// --- Hardware ---
LiquidCrystal_I2C lcd(0x27, 16, 2);

#define sensor 32
#define waterPump 14    // Gunakan GPIO 14
#define TRIGGER_PIN 0   // Tombol BOOT

WiFiClient espClient;
PubSubClient client(espClient);

long lastMsg = 0;
char msg[50];
int value = 0;

// --- Deklarasi Fungsi ---
void setup_wifi();
void configModeCallback(WiFiManager *myWiFiManager);
void reconnect();
void callback(char* topic, byte* payload, unsigned int length);
void soilMoistureSensor();
void checkResetButton();
void relayControl(bool state); // Fungsi baru khusus kontrol relay

void setup() {
  Serial.begin(115200);
  
  // --- FIX RELAY SETUP (OPEN DRAIN) ---
  // Jangan set ke OUTPUT dulu. Set ke INPUT (Hi-Z) agar relay OFF total.
  pinMode(waterPump, INPUT); 
  // ------------------------------------

  pinMode(TRIGGER_PIN, INPUT_PULLUP);

  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("HydroPlant Sys");
  lcd.setCursor(0, 1);
  lcd.print("Starting...");
  delay(2000);

  setup_wifi();

  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Moisture :");
  lcd.setCursor(0, 1);
  lcd.print("Motor is OFF");
}

void loop() {
  checkResetButton();

  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  long now = millis();
  if (now - lastMsg > 5000) {
    lastMsg = now;
    soilMoistureSensor();
  }
}

// --- FUNGSI KHUSUS KONTROL RELAY (SOLUSI INTI) ---
void relayControl(bool on) {
  if (on) {
    // UNTUK MENYALAKAN (Active LOW):
    // Jadikan OUTPUT dan tarik ke LOW (Ground)
    pinMode(waterPump, OUTPUT);
    digitalWrite(waterPump, LOW);
    
    lcd.setCursor(0, 1);
    lcd.print("Motor is ON ");
  } else {
    // UNTUK MEMATIKAN:
    // JANGAN tulis HIGH. Tapi jadikan INPUT.
    // Ini memutus arus total, sehingga relay ditarik ke 5V oleh resistor internalnya sendiri.
    pinMode(waterPump, INPUT);
    
    lcd.setCursor(0, 1);
    lcd.print("Motor is OFF");
  }
}

void callback(char* topic, byte* payload, unsigned int length) {
  String messageTemp;
  for (int i = 0; i < length; i++) {
    messageTemp += (char)payload[i];
  }
  
  if (String(topic) == topic_pump_subscribe) {
    if (messageTemp == "ON" || messageTemp == "1") {
      relayControl(true); // Panggil fungsi relay ON
    } else if (messageTemp == "OFF" || messageTemp == "0") {
      relayControl(false); // Panggil fungsi relay OFF
    }
  }
}

// ... (Sisa fungsi WiFiManager dan Reset sama seperti sebelumnya) ...

void setup_wifi() {
  WiFiManager wm;
  lcd.clear(); lcd.setCursor(0, 0); lcd.print("Connecting WiFi...");
  wm.setAPCallback(configModeCallback);
  wm.setConnectTimeout(20);
  if (!wm.autoConnect("HydroPlant")) Serial.println("Failed to connect");
  Serial.println("WiFi Connected!");
  lcd.clear(); lcd.setCursor(0, 0); lcd.print("Connected:");
  lcd.setCursor(0, 1); lcd.print(WiFi.localIP()); delay(2000);
}

void configModeCallback(WiFiManager *myWiFiManager) {
  lcd.clear(); lcd.setCursor(0, 0); lcd.print("Gagal Konek!");
  lcd.setCursor(0, 1); lcd.print("Mode Setup AP"); delay(2000);
  lcd.clear(); lcd.setCursor(0, 0); lcd.print("WiFi: HydroPlant");
  lcd.setCursor(0, 1); lcd.print("IP: 192.168.4.1");
}

void checkResetButton() {
  if (digitalRead(TRIGGER_PIN) == LOW) {
    delay(50);
    if (digitalRead(TRIGGER_PIN) == LOW) {
      unsigned long startPress = millis();
      bool isResetting = false;
      while (digitalRead(TRIGGER_PIN) == LOW) {
        unsigned long elapsed = millis() - startPress;
        lcd.setCursor(0, 0); lcd.print("Reset WiFi?     ");
        lcd.setCursor(0, 1);
        if (elapsed < 1000) lcd.print("Tahan 3 det...  ");
        else if (elapsed < 2000) lcd.print("Tahan 2 det...  ");
        else if (elapsed < 3000) lcd.print("Tahan 1 det...  ");
        else {
          isResetting = true;
          lcd.clear(); lcd.setCursor(0, 0); lcd.print("Resetting...");
          WiFiManager wm; wm.resetSettings(); 
          delay(1000); ESP.restart(); break; 
        }
        delay(100); 
      }
      if (!isResetting) {
        lcd.clear(); lcd.setCursor(0, 0); lcd.print("Batal Reset"); delay(1000); 
        lcd.clear(); lcd.setCursor(0, 0); lcd.print("Moisture :"); lcd.setCursor(0, 1);
        // Cek status berdasarkan mode pin
        // Jika OUTPUT (berarti sedang LOW/ON), jika INPUT (berarti OFF)
        // Agak tricky ngeceknya, kita asumsi OFF dulu kalau batal reset
        lcd.print("Motor is OFF");
        pinMode(waterPump, INPUT); // Paksa OFF biar aman
      }
    }
  }
}

void reconnect() {
  while (!client.connected()) {
    checkResetButton(); 
    Serial.print("Attempting MQTT connection...");
    if (client.connect(mqtt_client_id)) {
      Serial.println("connected");
      client.subscribe(topic_pump_subscribe);
    } else {
      Serial.print("failed, rc="); Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      unsigned long startWait = millis();
      while(millis() - startWait < 5000) { checkResetButton(); delay(10); }
    }
  }
}

void soilMoistureSensor() {
  value = analogRead(sensor);
  value = map(value, 4095, 0, 0, 100); 
  if(value > 100) value = 100; if(value < 0) value = 0;
  String payload = String(value);
  payload.toCharArray(msg, 50);
  client.publish(topic_moisture_publish, msg);
  lcd.setCursor(10, 0); lcd.print(value); lcd.print("%  ");
}
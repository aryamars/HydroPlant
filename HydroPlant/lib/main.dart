import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const HydroPlantApp());
}

class HydroPlantApp extends StatelessWidget {
  const HydroPlantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HydroPlant',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // --- Konfigurasi MQTT (Sesuai kode ESP32) ---
  final String broker = 'broker.hivemq.com';
  final String topicMoisture = 'plant/moisture';
  final String topicPump = 'plant/pump/control';
  
  // Client MQTT
  late MqttServerClient client;
  
  // State Aplikasi
  String moistureValue = "0";
  bool isPumpOn = false;
  String connectionStatus = "Disconnected";
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    setupMqtt();
  }

  // --- Fungsi Setup MQTT ---
  Future<void> setupMqtt() async {
    // Generate ID unik agar tidak bentrok
    client = MqttServerClient(broker, 'FlutterApp_${DateTime.now().millisecondsSinceEpoch}');
    client.port = 1883;
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('FlutterHydroPlant')
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMess;

    try {
      setState(() => connectionStatus = "Connecting...");
      await client.connect();
    } on NoConnectionException catch (e) {
      print('MQTT Client exception - $e');
      client.disconnect();
    } on SocketException catch (e) {
      print('MQTT Socket exception - $e');
      client.disconnect();
    }
  }

  // --- Callback saat Terhubung ---
  void onConnected() {
    setState(() {
      connectionStatus = "Connected to HydroPlant";
      isConnected = true;
    });
    print('MQTT Connected');

    // Subscribe ke topik Moisture
    client.subscribe(topicMoisture, MqttQos.atLeastOnce);

    // Listener untuk pesan masuk
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
      final String pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      // Cek topik dan update UI
      if (c[0].topic == topicMoisture) {
        setState(() {
          moistureValue = pt;
        });
      }
    });
  }

  // --- Callback saat Putus ---
  void onDisconnected() {
    setState(() {
      connectionStatus = "Disconnected";
      isConnected = false;
    });
    print('MQTT Disconnected');
  }

  // --- Fungsi Kontrol Pompa ---
  void togglePump(bool value) {
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum terhubung ke server MQTT!')),
      );
      return;
    }

    final builder = MqttClientPayloadBuilder();
    // Kirim "ON" atau "OFF" sesuai logika kode ESP32 kamu
    String payload = value ? "ON" : "OFF";
    builder.addString(payload);

    client.publishMessage(topicPump, MqttQos.atLeastOnce, builder.payload!);

    setState(() {
      isPumpOn = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Konversi string moisture ke double untuk visualisasi progress bar
    double moistureDouble = double.tryParse(moistureValue) ?? 0.0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('HydroPlant System', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Status Koneksi ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: isConnected ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isConnected ? Icons.wifi : Icons.wifi_off,
                    color: isConnected ? Colors.green[800] : Colors.red[800],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    connectionStatus,
                    style: TextStyle(
                      color: isConnected ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            // --- Tampilan Moisture (Lingkaran Besar) ---
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: moistureDouble / 100, // Konversi 0-100 ke 0.0-1.0
                    strokeWidth: 15,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      moistureDouble < 30 ? Colors.red : Colors.blue,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop, size: 40, color: Colors.blue),
                    Text(
                      "$moistureValue%",
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      "Soil Moisture",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 50),

            // --- Kartu Kontrol Pompa ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isPumpOn ? Colors.blue[100] : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.water_damage, 
                            color: isPumpOn ? Colors.blue : Colors.grey,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Water Pump",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isPumpOn ? "Status: ON" : "Status: OFF",
                              style: TextStyle(
                                color: isPumpOn ? Colors.blue : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: isPumpOn,
                      activeColor: Colors.blue,
                      onChanged: (val) {
                        togglePump(val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Tombol Refresh/Reconnect manual jika perlu
            if (!isConnected)
              ElevatedButton.icon(
                onPressed: setupMqtt,
                icon: const Icon(Icons.refresh),
                label: const Text("Reconnect MQTT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              )
          ],
        ),
      ),
    );
  }
}
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> openGoogleMaps(double latitude, double longitude) async {
    final String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final Uri url = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open Google Maps.';
    }
  }

  final player = AudioPlayer();

  Future<void> playSound() async {
    try {
      await player.play(
        AssetSource('audios/alert.mp3'),
      ); // Replace 'alert.mp3' with your audio file name
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nearby Accidents"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('accidents').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            List documents = snapshot.data!.docs;
            print(documents.length.toString());
            final changes = snapshot.data!.docChanges;
            for (var change in changes) {
              if (change.type == DocumentChangeType.added) {
                playSound();
              }
            }
            final firebaseFirestore = FirebaseFirestore.instance.collection(
              'accidents',
            );
            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                final docId = doc.id;
                final data = documents[index].data() as Map<String, dynamic>;
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  color: Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.redAccent),
                            SizedBox(width: 5),
                            Text(
                              "Location: ${data['latitude']} ${data['longitude']}",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.orange),
                            SizedBox(width: 5),
                            Text("Status: ${data['ambulance-status']}"),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  await firebaseFirestore.doc(docId).update({
                                    'ambulance-status': 'allocated',
                                  });
                                } catch (e) {
                                  throw Exception();
                                }
                              },

                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    data['ambulance-status'] == 'pending'
                                        ? Colors.yellowAccent
                                        : Colors.white,
                              ),
                              child: Text("Allocate"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                openGoogleMaps(
                                  double.parse(data['latitude']),
                                  double.parse(data['longitude']),
                                );
                              },
                              child: Text('Open maps'),
                            ),
                            ElevatedButton(
                              onPressed:
                                  data['ambulance-status'] == 'allocated'
                                      ? () async {
                                        try {
                                          await firebaseFirestore
                                              .doc(docId)
                                              .update({
                                                'ambulance-status': 'reached',
                                              });
                                        } catch (e) {
                                          throw Exception();
                                        }
                                      }
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    data['ambulance-status'] == 'allocated' ||
                                            data['ambulance-status'] ==
                                                'allocate'
                                        ? Colors.green
                                        : Colors.white,
                              ),
                              child: Text("Reached"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return Center(child: Text('Something went wrong'));
        },
      ),
    );
  }
}

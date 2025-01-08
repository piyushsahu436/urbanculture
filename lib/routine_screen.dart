import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RoutineScreen extends StatefulWidget {
  @override
  _RoutineScreenState createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  final List<Map<String, dynamic>> routineItems = [
    {'title': 'Cleanser', 'isCompleted': false, 'note': ''},
    {'title': 'Toner', 'isCompleted': false, 'note': ''},
    {'title': 'Moisturizer', 'isCompleted': false, 'note': ''},
    {'title': 'Sunscreen', 'isCompleted': false, 'note': ''},
    {'title': 'Lip Balm', 'isCompleted': false, 'note': ''},
  ];

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final ConfettiController confettiController = ConfettiController(duration: const Duration(seconds: 6));
  final ImagePicker _picker = ImagePicker();

  double completedSteps = 0;
  bool showCongratulations = false;
  bool hideCards = false;

  void _addNoteDialog(int index) {
    if (hideCards) return;

    TextEditingController noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Mark Your Moment  ${routineItems[index]['title']}',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 20,
            ),
          ),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(hintText: 'Write Here'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  routineItems[index]['note'] = noteController.text;
                  routineItems[index]['isCompleted'] = noteController.text.isNotEmpty;
                  _updateProgress();
                });
                _saveToFirestore(index);
                Navigator.of(context).pop();
              },
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNoteAlert(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Note not added for ${routineItems[index]['title']}'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveToFirestore(int index) async {
    final item = routineItems[index];
    final String currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    await firestore.collection('piyush').doc(currentDate).set({
      item['title']: {
        'time': item['time'],
        'isCompleted': item['isCompleted'],
        'note': item['note'],
        'timestamp': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  void _updateProgress() {
    setState(() {
      completedSteps = routineItems.where((item) => item['isCompleted']).length.toDouble();
      if (completedSteps == routineItems.length) {
        showCongratulations = true;
        hideCards = true;
        confettiController.play();

        Future.delayed(Duration(seconds: 5), () {
          setState(() {
            showCongratulations = false;
            hideCards = false;
          });
        });
      }
    });
  }

  void _pickImage(int index) async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _uploadImageToFirebase(photo, index);
    }
  }

  void _uploadImageToFirebase(XFile photo, int index) async {
    final file = File(photo.path);
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('routine_photos/$fileName');
      await ref.putFile(file);

      String photoUrl = await ref.getDownloadURL();
      setState(() {
        routineItems[index]['photoUrl'] = photoUrl;
      });

      await firestore.collection('routine_photos').add({
        'photoUrl': photoUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print('Error uploading photo: $e');
    }
  }

  @override
  void dispose() {
    confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('EEEE, MMM d, yyyy').format(now);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Daily Skincare Routine',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 22,
                ),
              ),
            ),
            Text(
              formattedDate,
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Divider(height: 15),
                    SizedBox(height: 25),
                    Text(
                      completedSteps.toInt() == routineItems.length
                          ? '🎉 All Steps Completed! 🎉'
                          : '${routineItems.length - completedSteps.toInt()} Step away from Streak',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    Slider(
                      value: completedSteps,
                      min: 0,
                      max: routineItems.length.toDouble(),
                      divisions: routineItems.length,
                      onChanged: (value) {},
                      activeColor: Colors.pink[200],
                      inactiveColor: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
              if (!hideCards)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: routineItems.length,
                    itemBuilder: (context, index) {
                      final item = routineItems[index];
                      return Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.horizontal,
                        onDismissed: (direction) {
                          if (direction == DismissDirection.startToEnd) {
                            _addNoteDialog(index);
                          } else if (direction == DismissDirection.endToStart && item['note'].isEmpty) {
                            _showNoteAlert(index);
                          }
                        },
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart && item['note'].isNotEmpty) {
                            return false;
                          }
                          return true;
                        },
                        background: Container(
                          color: Colors.blue,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.warning, color: Colors.white),
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(
                              item['isCompleted'] ? Icons.check_circle : Icons.circle_outlined,
                              color: item['isCompleted'] ? Colors.green : Colors.grey,
                            ),
                            title: Text(item['title'] ?? ''),
                            subtitle: Text(
                              item['note']?.isNotEmpty == true
                                  ? '${item['note']}'
                                  : 'Swipe left to add note',
                              style: TextStyle(color: Colors.grey),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.camera_alt, color: Colors.blue),
                                  onPressed: () => _pickImage(index),
                                ),
                                if (item['photoUrl'] != null)
                                  IconButton(
                                    icon: Icon(Icons.image, color: Colors.green),
                                    onPressed: () {
                                      // Display the image (optional)
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          if (showCongratulations)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConfettiWidget(
                      confettiController: confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      numberOfParticles: 50,
                      colors: [Colors.pink, Colors.blue, Colors.yellow, Colors.green],
                    ),
                    const Text(
                      '🎉 Congratulations! 🎉',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'You completed your routine!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

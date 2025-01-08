import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:urbanflutter/routine_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class StreakScreen extends StatefulWidget {
  @override
  _StreakScreenState createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  List<StreakData> data = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStreakData();

    Future.delayed(Duration.zero, () {
      _showHappyNewYearOffer();
    });
  }

  String getFormattedDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
  }

  Future<void> fetchStreakData() async {
    try {
      final CollectionReference collection = FirebaseFirestore.instance.collection('piyush');
      final List<StreakData> fetchedData = [];

      DateTime now = DateTime.now();
      DateTime monday = now.subtract(Duration(days: now.weekday - 1));

      final List<String> daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

      for (int i = 0; i < 7; i++) {
        DateTime currentDate = monday.add(Duration(days: i));
        String formattedDate = getFormattedDate(currentDate);

        DocumentSnapshot docSnapshot = await collection.doc(formattedDate).get();
        int streakValue = docSnapshot.exists ? 1 : 0;

        fetchedData.add(StreakData(daysOfWeek[i], streakValue));
      }

      setState(() {
        data = fetchedData;
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching streak data: $error');
      setState(() {
        isLoading = false;
      });
    }
  }


  void _showHappyNewYearOffer() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "🎉 Happy New Year Offer! 🎉",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enjoy a 50% discount on spa services!",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                "This offer is valid until the end of January 2025.",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Got it!",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Streaks',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Goal: 3 streak days",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streak Days',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.where((d) => d.streak > 0).length.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Daily Streak",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Last 30 Days +100%",
              style: GoogleFonts.poppins(
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  maximum: 1,
                  interval: 1,
                  isVisible: false,
                ),
                plotAreaBorderWidth: 0,
                series: <ChartSeries>[
                  ColumnSeries<StreakData, String>(
                    dataSource: data,
                    xValueMapper: (StreakData streak, _) => streak.day,
                    yValueMapper: (StreakData streak, _) => streak.streak,
                    color: Colors.pink.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Keep it up! You're on a roll.",
              style: GoogleFonts.poppins(
                fontSize: 16,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RoutineScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                'Get Started',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.pink.shade200,
        selectedLabelStyle: GoogleFonts.poppins(),
        unselectedLabelStyle: GoogleFonts.poppins(),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Routine',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Streaks',
          ),
        ],
      ),
    );
  }
}

class StreakData {
  final String day;
  final int streak;

  StreakData(this.day, this.streak);
}

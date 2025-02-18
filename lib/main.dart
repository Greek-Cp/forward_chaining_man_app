import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProgressTrackingScreen(),
    );
  }
}

class ProgressTrackingScreen extends StatefulWidget {
  @override
  _ProgressTrackingScreenState createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  Map<int, double> itemHeights = {}; // Menyimpan tinggi masing-masing item

  final List<Map<String, String>> steps = [
    {
      "title": "Menyukai Matematika",
      "description": "Memahami konsep angka",
      "category": "IPA"
    },
    {
      "title": "Menyukai Elektronika",
      "description": "Mengenal komponen listrik",
      "category": "IPA"
    },
    {
      "title": "Eksperimen Robotik",
      "description":
          "Membuat proyek kecilMembuat proyek kecilMembuat proyek kecilMembuat proyek kecilMembuat proyek kecilMembuat proyek kecilMembuat proyek kecilMembuat proyek kecilMembuat proyek kecilMembuat proyek kecil",
      "category": "Teknologi"
    },
    {
      "title": "Mempelajari Coding",
      "description":
          "Membuat proyek kecilMembuat proyek kecilMembuat proyek kecilMembuat proyek kecil",
      "category": "Teknologi"
    },
    {
      "title": "Membangun Aplikasi",
      "description": "Membuat aplikasi Flutter",
      "category": "Teknologi"
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5), // Durasi animasi
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  void _resetProgress() {
    _controller.reset();
    _controller.forward();
  }

  void updateItemHeight(int index, double height) {
    setState(() {
      itemHeights[index] = height;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Progress Tracking Timeline")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Column(
              children: List.generate(steps.length, (index) {
                double progressPerStep = 1.0 / steps.length;
                bool isCompleted = _progressAnimation.value >= 1.0;
                bool isActiveNow = (_progressAnimation.value >=
                        progressPerStep * index &&
                    _progressAnimation.value < progressPerStep * (index + 1));
                bool isLineVisible =
                    _progressAnimation.value > (progressPerStep * index);
                double lineHeight =
                    itemHeights[index] ?? 0.0; // Tinggi garis mengikuti item

                return TimelineTile(
                  step: index + 1,
                  title: steps[index]["title"]!,
                  description: steps[index]["description"]!,
                  category: steps[index]["category"]!,
                  isActive:
                      _progressAnimation.value > (progressPerStep * index),
                  isActiveNow: isActiveNow,
                  isLast: index == steps.length - 1,
                  isCompleted: isCompleted,
                  isLineVisible: isLineVisible,
                  lineHeight:
                      max(0, lineHeight * 0.8), // Menyesuaikan tinggi garis
                  onHeightCalculated: (height) =>
                      updateItemHeight(index, height),
                );
              }),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetProgress,
        child: Icon(Icons.refresh),
        backgroundColor: Colors.blue,
        tooltip: "Reset Progress",
      ),
    );
  }
}

class TimelineTile extends StatefulWidget {
  final int step;
  final String title;
  final String description;
  final String category;
  final bool isActive;
  final bool isActiveNow;
  final bool isLast;
  final bool isCompleted;
  final bool isLineVisible;
  final double lineHeight;
  final Function(double) onHeightCalculated;

  TimelineTile({
    required this.step,
    required this.title,
    required this.description,
    required this.category,
    this.isActive = false,
    this.isActiveNow = false,
    this.isLast = false,
    this.isCompleted = false,
    this.isLineVisible = false,
    this.lineHeight = 0.0,
    required this.onHeightCalculated,
  });

  @override
  _TimelineTileState createState() => _TimelineTileState();
}

class _TimelineTileState extends State<TimelineTile> {
  final GlobalKey _containerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _getContainerHeight());
  }

  void _getContainerHeight() {
    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      widget.onHeightCalculated(renderBox.size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color activeColor = widget.isCompleted ? Colors.green : Colors.blue;
    double scale = widget.isActiveNow ? 1.2 : 1.0;
    Color glowColor =
        widget.isActiveNow ? Colors.blue.withOpacity(0.8) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 1.0, end: scale),
                duration: Duration(milliseconds: 300),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: widget.isActive ? activeColor : Colors.grey,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: glowColor,
                            blurRadius: 10,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.step.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (!widget.isLast)
                AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  width: 3,
                  height: widget.isLineVisible ? max(0, widget.lineHeight) : 0,
                  color: widget.isActive ? activeColor : Colors.grey[300],
                ),
            ],
          ),
          SizedBox(width: 10),
          Expanded(
            child: Container(
              key: _containerKey, // Mengukur tinggi item
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.isActive ? activeColor : Colors.grey,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    widget.description,
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  Text(
                    widget.category,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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

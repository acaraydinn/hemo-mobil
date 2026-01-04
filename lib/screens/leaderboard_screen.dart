import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart'; // Merkezi sabitler eklendi
import '../utils/gamification_helper.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> leaders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      // Merkezi ApiConstants yapısını kullanıyoruz
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/leaderboard/'));

      if (response.statusCode == 200) {
        // UTF-8 Decode ile Türkçe karakterleri koruyoruz
        if (mounted) {
          setState(() {
            leaders = json.decode(utf8.decode(response.bodyBytes));
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Liderlik tablosu hatası: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Liderler Tablosu 🏆",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : leaders.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator( // Listeyi yenileme özelliği eklendi
        onRefresh: _fetchLeaderboard,
        color: const Color(0xFFD32F2F),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: leaders.length,
          itemBuilder: (context, index) {
            final user = leaders[index];
            return _buildLeaderCard(user, index + 1);
          },
        ),
      ),
    );
  }

  Widget _buildLeaderCard(dynamic user, int rank) {
    int points = user['points'] ?? 0;
    UserLevel levelInfo = GamificationHelper.getLevelInfo(points);

    Color rankColor;
    IconData rankIcon;
    double elevation;

    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
      rankIcon = Icons.emoji_events;
      elevation = 5;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
      rankIcon = Icons.emoji_events;
      elevation = 3;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
      rankIcon = Icons.emoji_events;
      elevation = 2;
    } else {
      rankColor = Colors.grey.shade300;
      rankIcon = Icons.star;
      elevation = 1;
    }

    return Card(
      elevation: elevation,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: rank <= 3
                ? LinearGradient(colors: [Colors.white, rankColor.withOpacity(0.15)])
                : null,
            color: Colors.white
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: rank <= 3 ? rankColor : Colors.grey[100],
                  shape: BoxShape.circle,
                  border: Border.all(color: rank <= 3 ? Colors.white : Colors.transparent, width: 2),
                  boxShadow: rank <= 3 ? [BoxShadow(color: rankColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] : []
              ),
              child: Center(
                child: rank <= 3
                    ? Icon(rankIcon, color: Colors.white, size: 28)
                    : Text("#$rank", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 18)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${user['first_name']} ${user['last_name']}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(levelInfo.badge, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 5),
                      Text(
                          levelInfo.title,
                          style: TextStyle(color: levelInfo.color, fontSize: 12, fontWeight: FontWeight.w600)
                      ),
                    ],
                  )
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20)
              ),
              child: Text(
                "$points P",
                style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text("Henüz sıralama oluşmadı.", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
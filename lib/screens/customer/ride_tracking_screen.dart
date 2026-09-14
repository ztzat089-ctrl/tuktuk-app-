import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RideTrackingScreen extends StatelessWidget {
  final String rideId;
  const RideTrackingScreen({super.key, required this.rideId});

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'جاري البحث عن كابتن...';
      case 'accepted':
        return 'الكابتن بالطريق إليك';
      case 'ongoing':
        return 'الرحلة جارية الآن';
      case 'completed':
        return 'اكتملت الرحلة، شكراً لاستخدامك تكتك';
      case 'cancelled':
        return 'تم إلغاء الرحلة';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('متابعة الرحلة')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .doc(rideId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final ride = snapshot.data!.data() as Map<String, dynamic>;
          final status = ride['status'] ?? 'pending';

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(
                  status == 'completed'
                      ? Icons.check_circle
                      : Icons.electric_rickshaw,
                  size: 80,
                  color: const Color(0xFFF7B500),
                ),
                const SizedBox(height: 20),
                Text(
                  _statusText(status),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _infoRow('إلى', ride['toAddress'] ?? ''),
                        const Divider(),
                        _infoRow('الأجرة', '${ride['fare']} د.ع'),
                        if (ride['captainName'] != null) ...[
                          const Divider(),
                          _infoRow('الكابتن', ride['captainName']),
                        ],
                      ],
                    ),
                  ),
                ),
                if (status == 'pending') ...[
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection('rides')
                          .doc(rideId)
                          .update({'status': 'cancelled'});
                      Navigator.pop(context);
                    },
                    child: const Text('إلغاء الطلب',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

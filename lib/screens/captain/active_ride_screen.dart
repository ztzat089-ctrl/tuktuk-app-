import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';

class ActiveRideScreen extends StatelessWidget {
  final String rideId;
  const ActiveRideScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرحلة الحالية')),
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
          final status = ride['status'];

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الزبون: ${ride['customerName']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('من: ${ride['fromAddress']}'),
                        Text('إلى: ${ride['toAddress']}'),
                        const SizedBox(height: 8),
                        Text('الأجرة: ${ride['fare']} د.ع',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (status == 'accepted')
                  ElevatedButton(
                    onPressed: () =>
                        FirebaseService.updateRideStatus(rideId, 'ongoing'),
                    child: const Text('بدء الرحلة'),
                  ),
                if (status == 'ongoing')
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () async {
                      await FirebaseService.completeRideAndPayCaptain(
                        rideId: rideId,
                        captainId: FirebaseService.currentUid!,
                        fare: (ride['fare'] as num).toDouble(),
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('إنهاء الرحلة وتحصيل الأجرة'),
                  ),
                if (status == 'completed')
                  const Text('تم إنهاء الرحلة بنجاح ✅',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.green, fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}

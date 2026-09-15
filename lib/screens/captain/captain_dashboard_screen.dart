import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/firebase_service.dart';
import 'active_ride_screen.dart';

class CaptainDashboardScreen extends StatefulWidget {
  const CaptainDashboardScreen({super.key});

  @override
  State<CaptainDashboardScreen> createState() =>
      _CaptainDashboardScreenState();
}

class _CaptainDashboardScreenState extends State<CaptainDashboardScreen> {
  bool _available = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data =
        await FirebaseService.getUserData(FirebaseService.currentUid!);
    if (mounted) {
      setState(() {
        _userData = data;
        _available = data?['isAvailable'] ?? false;
      });
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _available = value);
    await FirebaseService.setCaptainAvailability(
        FirebaseService.currentUid!, value);

    if (value) {
      // تحديث الموقع اللحظي عند تفعيل الاستعداد لاستقبال الطلبات
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      await FirebaseService.updateCaptainLocation(
          FirebaseService.currentUid!, pos.latitude, pos.longitude);
    }
  }

  Future<void> _showRideRequestDialog(
      String rideId, Map<String, dynamic> ride) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('طلب رحلة جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الزبون: ${ride['customerName']}'),
            const SizedBox(height: 8),
            Text('من: ${ride['fromAddress']}'),
            Text('إلى: ${ride['toAddress']}'),
            const SizedBox(height: 8),
            Text('الأجرة: ${ride['fare']} د.ع',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('رفض', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseService.acceptRide(
                rideId: rideId,
                captainId: FirebaseService.currentUid!,
                captainName: _userData?['name'] ?? 'كابتن',
              );
              if (!mounted) return;
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ActiveRideScreen(rideId: rideId)),
              );
            },
            child: const Text('قبول الرحلة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('هلا بالكابتن ${_userData?['name'] ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseService.logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط التوفر
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _available ? Colors.green : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _available ? 'متاح الآن' : 'غير متاح',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                Switch(
                  value: _available,
                  onChanged: _toggleAvailability,
                  activeColor: Colors.white,
                ),
              ],
            ),
          ),

          // ملخص الأرباح
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                    child: _StatCard(
                        label: 'الأرباح',
                        value: '${_userData?['totalEarnings'] ?? 0} د.ع')),
                const SizedBox(width: 8),
                Expanded(
                    child: _StatCard(
                        label: 'الرحلات',
                        value: '${_userData?['totalTrips'] ?? 0}')),
                const SizedBox(width: 8),
                Expanded(
                    child: _StatCard(
                        label: 'الرصيد',
                        value: '${_userData?['walletBalance'] ?? 0} د.ع')),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('طلبات الرحلات',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),

          // قائمة الطلبات اللحظية (تظهر فقط عندما الكابتن متاح)
          Expanded(
            child: !_available
                ? const Center(
                    child: Text('فعّل "متاح الآن" لاستقبال طلبات الرحلات'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseService.pendingRidesStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(
                            child: Text('لا توجد طلبات حالياً'));
                      }
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final ride =
                              docs[i].data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.electric_rickshaw,
                                  color: Color(0xFFF7B500)),
                              title: Text(ride['toAddress'] ?? ''),
                              subtitle: Text('الأجرة: ${ride['fare']} د.ع'),
                              trailing: ElevatedButton(
                                onPressed: () => _showRideRequestDialog(
                                    docs[i].id, ride),
                                child: const Text('عرض'),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }
}

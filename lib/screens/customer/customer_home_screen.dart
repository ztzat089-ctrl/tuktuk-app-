import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/firebase_service.dart';
import 'ride_tracking_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _destinationCtrl = TextEditingController();
  bool _requesting = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final pos = await Geolocator.getCurrentPosition();
    if (mounted) setState(() => _currentPosition = pos);
  }

  /// مثال مبسّط لحساب الأجرة التقديرية: سعر أساس + سعر لكل كم
  double _estimateFare(double distanceKm) {
    const baseFare = 1000.0; // د.ع
    const perKm = 500.0; // د.ع لكل كم
    return baseFare + (distanceKm * perKm);
  }

  Future<void> _requestRide() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تفعيل خدمة الموقع أولاً')),
      );
      return;
    }
    if (_destinationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال وجهتك')),
      );
      return;
    }

    setState(() => _requesting = true);

    final uid = FirebaseService.currentUid!;
    final userData = await FirebaseService.getUserData(uid);

    // ملاحظة: بالنسخة الكاملة، الإحداثيات الوجهة تُستخرج عبر Geocoding
    // أو باختيار نقطة على الخريطة. هنا نستخدم قيمة تقديرية توضيحية.
    const estimatedDistanceKm = 5.0;
    final fare = _estimateFare(estimatedDistanceKm);

    final rideId = await FirebaseService.createRideRequest(
      customerId: uid,
      customerName: userData?['name'] ?? 'زبون',
      fromLat: _currentPosition!.latitude,
      fromLng: _currentPosition!.longitude,
      fromAddress: 'موقعي الحالي',
      toLat: _currentPosition!.latitude + 0.01,
      toLng: _currentPosition!.longitude + 0.01,
      toAddress: _destinationCtrl.text.trim(),
      fare: fare,
    );

    if (!mounted) return;
    setState(() => _requesting = false);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RideTrackingScreen(rideId: rideId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب رحلة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseService.logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentPosition == null
                            ? 'جاري تحديد موقعك...'
                            : 'من: موقعي الحالي',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _destinationCtrl,
              decoration: const InputDecoration(
                labelText: 'إلى أين تريد الذهاب؟',
                prefixIcon: Icon(Icons.flag_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _requesting ? null : _requestRide,
                child: _requesting
                    ? const CircularProgressIndicator()
                    : const Text('اطلب تكتك الآن',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('رحلاتي السابقة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.userRidesHistory(
                    FirebaseService.currentUid!, 'customer'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('لا توجد رحلات بعد'));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final ride = docs[i].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(Icons.electric_rickshaw),
                        title: Text(ride['toAddress'] ?? ''),
                        subtitle: Text('الحالة: ${ride['status']}'),
                        trailing: Text('${ride['fare']} د.ع'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

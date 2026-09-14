import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// خدمة مركزية تتعامل مع كل عمليات Firebase (تسجيل، مستخدمين، رحلات)
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------- المصادقة ----------------

  /// إنشاء حساب جديد (زبون أو كابتن)
  static Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role, // 'customer' or 'captain'
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'walletBalance': 0,
        'totalEarnings': 0,
        'totalTrips': 0,
        'rating': null,
        'isAvailable': false,
      });

      return null; // لا يوجد خطأ
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'حدث خطأ أثناء إنشاء الحساب';
    }
  }

  /// تسجيل الدخول
  static Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'خطأ في تسجيل الدخول';
    }
  }

  static Future<void> logout() => _auth.signOut();

  static String? get currentUid => _auth.currentUser?.uid;

  /// جلب نوع الحساب (customer / captain)
  static Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['role'] as String?;
  }

  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // ---------------- حالة الكابتن ----------------

  static Future<void> setCaptainAvailability(String uid, bool isAvailable) {
    return _db.collection('users').doc(uid).update({
      'isAvailable': isAvailable,
    });
  }

  static Future<void> updateCaptainLocation(
      String uid, double lat, double lng) {
    return _db.collection('users').doc(uid).update({
      'location': GeoPoint(lat, lng),
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    });
  }

  // ---------------- الرحلات ----------------

  /// إنشاء طلب رحلة جديد من الزبون
  static Future<String> createRideRequest({
    required String customerId,
    required String customerName,
    required double fromLat,
    required double fromLng,
    required String fromAddress,
    required double toLat,
    required double toLng,
    required String toAddress,
    required double fare,
  }) async {
    final doc = await _db.collection('rides').add({
      'customerId': customerId,
      'customerName': customerName,
      'captainId': null,
      'captainName': null,
      'fromLat': fromLat,
      'fromLng': fromLng,
      'fromAddress': fromAddress,
      'toLat': toLat,
      'toLng': toLng,
      'toAddress': toAddress,
      'fare': fare,
      'status': 'pending', // pending -> accepted -> ongoing -> completed / cancelled
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// بث لحظي لطلبات الرحلات المعلقة (يستخدمه الكابتن)
  static Stream<QuerySnapshot> pendingRidesStream() {
    return _db
        .collection('rides')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// بث لحظي لحالة رحلة معينة (يستخدمه الزبون لمتابعة رحلته)
  static Stream<DocumentSnapshot> rideStream(String rideId) {
    return _db.collection('rides').doc(rideId).snapshots();
  }

  static Future<void> acceptRide({
    required String rideId,
    required String captainId,
    required String captainName,
  }) async {
    await _db.collection('rides').doc(rideId).update({
      'captainId': captainId,
      'captainName': captainName,
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateRideStatus(String rideId, String status) {
    return _db.collection('rides').doc(rideId).update({'status': status});
  }

  /// عند اكتمال الرحلة: تحديث أرباح ورصيد الكابتن
  static Future<void> completeRideAndPayCaptain({
    required String rideId,
    required String captainId,
    required double fare,
  }) async {
    final captainRef = _db.collection('users').doc(captainId);
    final rideRef = _db.collection('rides').doc(rideId);

    await _db.runTransaction((tx) async {
      final captainSnap = await tx.get(captainRef);
      final currentBalance =
          (captainSnap.data()?['walletBalance'] ?? 0).toDouble();
      final currentEarnings =
          (captainSnap.data()?['totalEarnings'] ?? 0).toDouble();
      final currentTrips = (captainSnap.data()?['totalTrips'] ?? 0) as int;

      tx.update(captainRef, {
        'walletBalance': currentBalance + fare,
        'totalEarnings': currentEarnings + fare,
        'totalTrips': currentTrips + 1,
      });

      tx.update(rideRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// رحلات الكابتن أو الزبون السابقة
  static Stream<QuerySnapshot> userRidesHistory(String uid, String role) {
    final field = role == 'captain' ? 'captainId' : 'customerId';
    return _db
        .collection('rides')
        .where(field, isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}

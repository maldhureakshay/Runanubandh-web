import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dynamically fetches the EC2 public IP from the Firestore config.
/// Reusable globally by any page/feature needing to call the EC2 backend.
final ec2IpProvider = FutureProvider<String>((ref) async {
  return 'https://api.mali-runanubandh.in';
});

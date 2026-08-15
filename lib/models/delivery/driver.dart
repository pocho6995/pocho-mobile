import '../../utils/image_url_helper.dart';

class Driver {
  Driver({
    required this.id,
    required this.userId,
    required this.phoneNumber,
    required this.fullName,
    required this.email,
    required this.status,
    required this.rating,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.balance,
    required this.totalEarnings,
    required this.isOnline,
    required this.autoAcceptOrders,
    this.photoUrl,
    this.currentLatitude,
    this.currentLongitude,
    this.adminComment,
    this.createdAt,
    this.updatedAt,
    this.approvedAt,
    this.regionId,
  });

  final int id;
  final int userId;
  final String phoneNumber;
  final String fullName;
  final String email;
  final String? photoUrl;
  final String status; // pending, approved, rejected, suspended, offline, online
  final double rating;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double balance;
  final double totalEarnings;
  final double? currentLatitude;
  final double? currentLongitude;
  final bool isOnline;
  final bool autoAcceptOrders;
  final String? adminComment;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;
  final int? regionId;

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isSuspended => status == 'suspended';

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      phoneNumber: json['phone_number'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      photoUrl: ImageUrlHelper.getFullImageUrl(json['photo_url'] as String?),
      status: json['status'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['total_orders'] as int? ?? 0,
      completedOrders: json['completed_orders'] as int? ?? 0,
      cancelledOrders: json['cancelled_orders'] as int? ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      currentLatitude: json['current_latitude'] != null
          ? (json['current_latitude'] as num).toDouble()
          : null,
      currentLongitude: json['current_longitude'] != null
          ? (json['current_longitude'] as num).toDouble()
          : null,
      isOnline: json['is_online'] as bool? ?? false,
      autoAcceptOrders: json['auto_accept_orders'] as bool? ?? false,
      adminComment: json['admin_comment'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      regionId: json['region_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'phone_number': phoneNumber,
      'full_name': fullName,
      'email': email,
      'photo_url': photoUrl,
      'status': status,
      'rating': rating,
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'cancelled_orders': cancelledOrders,
      'balance': balance,
      'total_earnings': totalEarnings,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'is_online': isOnline,
      'auto_accept_orders': autoAcceptOrders,
      'admin_comment': adminComment,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'region_id': regionId,
    };
  }
}

class DriverStatistics {
  DriverStatistics({
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.rating,
    required this.totalEarnings,
    required this.balance,
    this.onlineHoursToday,
    required this.ordersToday,
    required this.earningsToday,
  });

  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double rating;
  final double totalEarnings;
  final double balance;
  final double? onlineHoursToday;
  final int ordersToday;
  final double earningsToday;

  factory DriverStatistics.fromJson(Map<String, dynamic> json) {
    return DriverStatistics(
      totalOrders: json['total_orders'] as int? ?? 0,
      completedOrders: json['completed_orders'] as int? ?? 0,
      cancelledOrders: json['cancelled_orders'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      onlineHoursToday: json['online_hours_today'] != null
          ? (json['online_hours_today'] as num).toDouble()
          : null,
      ordersToday: json['orders_today'] as int? ?? 0,
      earningsToday: (json['earnings_today'] as num?)?.toDouble() ?? 0.0,
    );
  }
}






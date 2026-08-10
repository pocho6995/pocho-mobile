import 'profile_document.dart';

class ProfileDocuments {
  final ProfileDocument passport;
  final ProfileDocument drivingLicense;

  ProfileDocuments({
    required this.passport,
    required this.drivingLicense,
  });

  factory ProfileDocuments.fromJson(Map<String, dynamic> json) {
    return ProfileDocuments(
      passport: ProfileDocument.fromJson(
        json['passport'] as Map<String, dynamic>,
      ),
      drivingLicense: ProfileDocument.fromJson(
        json['driving_license'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'passport': passport.toJson(),
      'driving_license': drivingLicense.toJson(),
    };
  }
}













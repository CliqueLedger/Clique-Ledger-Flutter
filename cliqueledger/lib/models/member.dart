
import 'package:json_annotation/json_annotation.dart';

class Member{
   @JsonKey(name: "member_name")
  final String name;
  @JsonKey(name: "member_id")
  final String memberId;

  @JsonKey(name: "user_id")
  final String userId;
  final String email;
  bool isAdmin;

  Member({
    required this.name,
    required this.memberId,
    required this.userId,
    required this.email,
    required this.isAdmin
  });
 
  

  factory Member.fromJson(Map<String,dynamic> json){
    return Member(
      name: json["member_name"],
      memberId: json["member_id"],
      userId: json['user_id'],
      email: json['email'],
      isAdmin: json['is_admin']
      );
  }
  Map<String,dynamic> toJson(){
    return {
      'member_name':name,
      'member_id':memberId,
      'user_id': userId,
      'email': email,
      'is_admin':isAdmin
    };

  }
}
class User {
  final String? id;
  final String? name;
  final String? email;
  final String? role;
  final String? tlName;
  final String? region;
  final String? province;
  final String? area;
  final String? profileImage;
  final String? noKtp;
  final String? noJamsostek;
  final String? noNpwp;
  final String? gender;
  final String? birthDate;
  final String? joinDate;
  final String? motherName;
  final String? religion;
  final String? education;
  final String? address;
  final String? phone;
  
  User({
    this.id,
    this.name,
    this.email,
    this.role,
    this.tlName,
    this.region,
    this.province,
    this.area,
    this.profileImage,
    this.noKtp,
    this.noJamsostek,
    this.noNpwp,
    this.gender,
    this.birthDate,
    this.joinDate,
    this.motherName,
    this.religion,
    this.education,
    this.address,
    this.phone,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      tlName: json['tl_name'],
      region: json['region'],
      province: json['province'],
      area: json['area'],
      profileImage: json['profile_image'],
      noKtp: json['no_ktp'],
      noJamsostek: json['no_jamsostek'],
      noNpwp: json['no_npwp'],
      gender: json['gender'],
      birthDate: json['birth_date'],
      joinDate: json['join_date'],
      motherName: json['mother_name'],
      religion: json['religion'],
      education: json['education'],
      address: json['address'],
      phone: json['phone'],
    );
  }
  
  Map<String, String> toJson() {
    return {
      if (id != null) 'id': id!,
      if (name != null) 'name': name!,
      if (email != null) 'email': email!,
      if (role != null) 'role': role!,
      if (tlName != null) 'tl_name': tlName!,
      if (region != null) 'region': region!,
      if (province != null) 'province': province!,
      if (area != null) 'area': area!,
      if (noKtp != null) 'no_ktp': noKtp!,
      if (noJamsostek != null) 'no_jamsostek': noJamsostek!,
      if (noNpwp != null) 'no_npwp': noNpwp!,
      if (gender != null) 'gender': gender!,
      if (birthDate != null) 'birth_date': birthDate!,
      if (joinDate != null) 'join_date': joinDate!,
      if (motherName != null) 'mother_name': motherName!,
      if (religion != null) 'religion': religion!,
      if (education != null) 'education': education!,
      if (address != null) 'address': address!,
      if (phone != null) 'phone': phone!,
    };
  }
}
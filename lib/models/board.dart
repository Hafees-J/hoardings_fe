class Board {
  final int id;
  final String location;
  final double latitude;
  final double longitude;
  final String image;
  final double amount;
  final String? renewalAt;
  final String? nextRenewalAt;
  final String? renewalBy;
  final String? createdBy;

  Board({
    required this.id,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.image,
    required this.amount,
    this.renewalAt,
    this.nextRenewalAt,
    this.renewalBy,
    this.createdBy,
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'],
      location: json['location'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      image: json['image'] != null
    ? (json['image'].toString().startsWith('http')
        ? json['image'] // already full URL
        : "http://127.0.0.1:8000${json['image']}") // relative path
    : '',

      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      renewalAt: json['renewal_at'],
      nextRenewalAt: json['next_renewal_at'],
      renewalBy: json['renewalby'],
      createdBy: json['createdby'],
    );
  }
}

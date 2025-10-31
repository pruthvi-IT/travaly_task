import 'package:flutter/material.dart';

class Hotel {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final double? rating;
  final double? price;
  final String? currency;
  final String? imageUrl;
  final List<String>? amenities;
  final String? phoneNumber;
  final String? email;

  Hotel({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.city,
    this.state,
    this.country,
    this.rating,
    this.price,
    this.currency,
    this.imageUrl,
    this.amenities,
    this.phoneNumber,
    this.email,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    // Handle different API response structures
    try {
      // Safely determine the rating value
      dynamic ratingValue;
      final googleReview = json['googleReview'];
      if (googleReview is Map && googleReview['reviewPresent'] == true) {
        final data = googleReview['data'];
        ratingValue = (data is Map) ? data['overallRating'] : json['propertyStar'];
      } else {
        ratingValue = json['propertyStar'];
      }

      // Handle different API response formats
      if (json.containsKey('propertyCode') || json.containsKey('propertyName')) {
        // Handle property API format
        return Hotel(
          id: json['propertyCode']?.toString() ?? UniqueKey().toString(),
          name: json['propertyName'] ?? 'Unknown Hotel',
          description: json['propertyPoliciesAndAmmenities']?['data']?['propertyRestriction'] as String? ?? _composePolicies(json['propertyPoliciesAndAmmenities']?['data']),
          address: json['propertyAddress']?['street'],
          city: json['propertyAddress']?['city'],
          state: json['propertyAddress']?['state'],
          country: json['propertyAddress']?['country'],
          rating: _parseDouble(ratingValue),
          price: _parseDouble(json['staticPrice']?['amount']) ?? _parseDouble(json['markedPrice']?['amount']) ?? _parseDouble(json['propertyMinPrice']?['amount']),
          currency: json['staticPrice']?['currencySymbol'] ?? json['markedPrice']?['currencySymbol'] ?? json['propertyMinPrice']?['currencySymbol'] ?? '₹',
          imageUrl: _extractImageUrl(json),
          amenities: _buildAmenities(json['propertyPoliciesAndAmmenities']?['data']),
          phoneNumber: null,
          email: null,
        );
      } else {
        // Handle standard API format
        return Hotel(
          id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
          name: json['name']?.toString() ?? 'Unknown Hotel',
          description: json['description']?.toString() ?? json['about']?.toString(),
          address: json['address']?.toString() ?? json['location']?.toString(),
          city: json['city']?.toString() ?? json['location']?.toString(),
          state: json['state']?.toString(),
          country: json['country']?.toString(),
          rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) : null,
          price: json['price'] != null ? double.tryParse(json['price'].toString()) : 
                json['minPrice'] != null ? double.tryParse(json['minPrice'].toString()) : null,
          currency: json['currency']?.toString() ?? 'USD',
          imageUrl: json['imageUrl']?.toString() ?? 
                  (json['images'] != null && json['images'] is List && (json['images'] as List).isNotEmpty ? 
                  (json['images'] as List).first.toString() : 
                  json['images']?.toString() ?? json['image']?.toString()),
          amenities: _buildAmenities(json['amenities'] as Map<String, dynamic>?),
          phoneNumber: json['phoneNumber']?.toString(),
          email: json['email']?.toString(),
        );
      }
    } catch (e) {
      debugPrint('[Hotel] Error parsing hotel: $e');
      return Hotel(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? json['propertyCode']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['propertyName']?.toString() ?? json['name']?.toString() ?? 'Hotel',
      );
    }
  }
  
  // Helper function to build amenities list from the API data
  static List<String> _buildAmenities(Map<String, dynamic>? amenitiesData) {
    if (amenitiesData == null) return [];
    final List<String> amenities = [];
    if (amenitiesData['freeWifi'] == true) {
      amenities.add('WiFi');
    }
    if (amenitiesData['coupleFriendly'] == true) {
      amenities.add('Couple Friendly');
    }
    if (amenitiesData['petsAllowed'] == true) {
      amenities.add('Pets Allowed');
    }
    if (amenitiesData['freeCancellation'] == true) {
      amenities.add('Free Cancellation');
    }
    if (amenitiesData['breakfast'] == true) {
      amenities.add('Breakfast');
    }
    if (amenitiesData['parking'] == true) {
      amenities.add('Parking');
    }
    return amenities;
  }

  factory Hotel.fromSuggestionJson(Map<String, dynamic> json) {
    // This constructor handles the specific format of the searchAutoComplete API response
    return Hotel(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      name: json['name'] ?? 'Unknown',
      city: json['city'],
      state: json['state'],
      country: json['country'],
      // Other fields are typically not available in the suggestion response
      amenities: null,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String? _extractImageUrl(Map<String, dynamic> json) {
    final raw = json['propertyImage'];
    if (raw is String) return _sanitizeImageUrl(raw);
    if (raw is Map) {
      final full = raw['fullUrl'] ?? raw['url'] ?? raw['thumbnailUrl'];
      return full?.toString();
    }
    return json['image']?.toString();
  }

  static String _sanitizeImageUrl(String url) {
    var cleaned = url.replaceAll('`', '').trim();
    if (cleaned.endsWith(',')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }

  static String? _composePolicies(dynamic data) {
    if (data is! Map) return null;
    final parts = <String>[];
    final cancel = data['cancelPolicy'];
    final refund = data['refundPolicy'];
    final child = data['childPolicy'];
    if (cancel is String && cancel.trim().isNotEmpty) {
      parts.add('Cancellation: $cancel');
    }
    if (refund is String && refund.trim().isNotEmpty) {
      parts.add('Refund: $refund');
    }
    if (child is String && child.trim().isNotEmpty) {
      parts.add('Child: $child');
    }
    return parts.isEmpty ? null : parts.join('\n\n');
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'rating': rating,
      'price': price,
      'currency': currency,
      'image_url': imageUrl,
      'amenities': amenities,
      'phone_number': phoneNumber,
      'email': email,
    };
  }

  String get fullLocation {
    final parts = <String>[];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  String get displayPrice {
    if (price == null) return 'Price not available';
    return '$currency ${price!.toStringAsFixed(0)}';
  }
}

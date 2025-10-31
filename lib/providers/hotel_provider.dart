import 'package:flutter/material.dart';
import '../models/hotel.dart';
import '../services/api_service.dart';

class HotelProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Hotel> _hotels = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 1;

  // Last known search
  String _country = 'India';
  String _state = '';
  String _city = '';

  // === Getters for UI ===
  List<Hotel> get hotels => _hotels;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get isReady => _api.isReady;

  HotelProvider() {
    debugPrint('[HotelProvider] Initialized');
  }

  // === Update Visitor Token ===
  void updateVisitorToken(String? token) {
    if (token != null && token.isNotEmpty) {
      _api.updateVisitorToken(token);
      debugPrint('[HotelProvider] Visitor token updated.');
    }
  }

  // === MAIN SEARCH (Paginated) ===
  Future<void> searchHotels({
    required String query,
    bool isNewSearch = true,
  }) async {
    debugPrint(
      '[HotelProvider] searchHotels called | Query: $query | isNewSearch: $isNewSearch',
    );

    if (query.trim().isEmpty) {
      _error = 'Please enter a search query';
      notifyListeners();
      return;
    }

    if (isNewSearch) {
      _hotels.clear();
      _isLoading = true;
      _hasMore = true;
      _currentPage = 1;
      _error = null;
    } else {
      _isLoadingMore = true;
    }
    notifyListeners();

    _city = query;

    try {
      // The API service fetches a broad list (e.g., by city).
      // We will perform fine-grained filtering on the client side.
      final response = await _api.getPropertyList(
        query: query,
        limit: 10,
        page: _currentPage,
      );

      if (response['status'] == true) {
        final data = response['data'];

        // ✅ 1. Correctly parse 'data' as a direct list.
        if (data is! List) {
          throw Exception(
            "API response 'data' field is not a list as expected.",
          );
        }

        final List<dynamic> hotelsData = data;
        debugPrint(
          '[HotelProvider] Received ${hotelsData.length} hotels from API.',
        );

        final allFetchedHotels = hotelsData
            .map((item) {
              try {
                return Hotel.fromJson(item as Map<String, dynamic>);
              } catch (e) {
                debugPrint(
                  '[HotelProvider] JSON parse error for item $item: $e',
                );
                return null;
              }
            })
            .whereType<Hotel>()
            .toList();

        // ✅ 2. Filter results by query (case-insensitive, multi-field).
        final lowerCaseQuery = query.toLowerCase();
        final filteredHotels = allFetchedHotels.where((hotel) {
          final nameMatch = hotel.name.toLowerCase().contains(lowerCaseQuery);
          final cityMatch =
              hotel.city?.toLowerCase().contains(lowerCaseQuery) ?? false;
          final countryMatch =
              hotel.country?.toLowerCase().contains(lowerCaseQuery) ?? false;
          final streetMatch =
              hotel.address?.toLowerCase().contains(lowerCaseQuery) ?? false;
          return nameMatch || cityMatch || countryMatch || streetMatch;
        }).toList();

        debugPrint(
          '[HotelProvider] Parsed ${allFetchedHotels.length} hotels, filtered down to ${filteredHotels.length}.',
        );

        // ✅ 3. Handle empty results gracefully.
        if (filteredHotels.isEmpty) {
          if (isNewSearch) {
            _error = 'No matching hotels found for "$query".';
            _hotels.clear(); // Ensure list is empty on UI
          }
          _hasMore = false; // No more pages to load
        } else {
          // ✅ 4. Properly update hotels list for new search vs. pagination.
          if (isNewSearch) {
            _hotels = filteredHotels;
          } else {
            // Add only new hotels to avoid duplicates
            _hotels.addAll(
              filteredHotels.where(
                (h) => !_hotels.any((existing) => existing.id == h.id),
              ),
            );
          }

          // ✅ 5. Correctly update pagination state.
          // Pagination is based on the *fetched* data, not the filtered data.
          // If the API returns less than the limit, we know there are no more pages.
          if (allFetchedHotels.length < 10) {
            _hasMore = false; // Last page reached
          } else {
            _currentPage++; // Increment for the next 'loadMore' call
          }
          _error = null; // Clear previous errors on success
        }
      } else {
        // Handle API-level errors
        _error =
            response['message'] as String? ?? 'An unknown API error occurred.';
        _hasMore = false;
      }
    } catch (e) {
      _error =
          'Failed to fetch hotels. Please check your connection and try again.';
      _hasMore = false;
      debugPrint('[HotelProvider] Exception: $e');
    }

    _isLoading = false;
    _isLoadingMore = false;
    // ✅ 6. Notifying listeners at the end to update UI with the final state.
    notifyListeners();
  }

  // === Load More (Pagination) ===
  Future<void> loadMore({required String query}) async {
    if (!_isLoading && !_isLoadingMore && _hasMore) {
      await searchHotels(query: query, isNewSearch: false);
    }
  }

  // === Clear Search ===
  void clearResults() {
    _hotels.clear();
    _error = null;
    _hasMore = true;
    _currentPage = 1;
    notifyListeners();
  }
}

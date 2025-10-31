import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travaly_assignment/providers/hotel_provider.dart';
import '../providers/auth_provider.dart';
import '../models/hotel.dart';
import '../widgets/hotel_card.dart';
import 'dart:async';

import 'search_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SearchController _searchController = SearchController();
  Timer? _debounce;

  // Sample hotel data for display
  final List<Hotel> _sampleHotels = [
    Hotel(
      id: '1',
      name: 'The Grandest Mumbai Hotel',
      city: 'Mumbai',
      state: 'Maharashtra',
      country: 'India',
      rating: 4.5,
      price: 3500,
      currency: 'INR',
      imageUrl:
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
      amenities: ['WiFi', 'Pool', 'Gym', 'Restaurant'],
      description: 'Luxury hotel in the heart of Mumbai with stunning views',
    ),
    Hotel(
      id: '2',
      name: 'Delhi Palace Resort',
      city: 'New Delhi',
      state: 'Delhi',
      country: 'India',
      rating: 4.3,
      price: 4200,
      currency: 'INR',
      imageUrl:
          'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800',
      amenities: ['WiFi', 'Spa', 'Restaurant', 'Bar'],
      description: 'Experience royal luxury in the capital city',
    ),
    Hotel(
      id: '3',
      name: 'Bangalore Business Inn',
      city: 'Bangalore',
      state: 'Karnataka',
      country: 'India',
      rating: 4.2,
      price: 2800,
      currency: 'INR',
      imageUrl:
          'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800',
      amenities: ['WiFi', 'Conference Room', 'Gym', 'Parking'],
      description: 'Perfect for business travelers in tech hub',
    ),
    Hotel(
      id: '4',
      name: 'Goa Beach Resort',
      city: 'Goa',
      state: 'Goa',
      country: 'India',
      rating: 4.7,
      price: 5500,
      currency: 'INR',
      imageUrl:
          'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800',
      amenities: ['Beach Access', 'Pool', 'Water Sports', 'Restaurant'],
      description: 'Beachfront paradise with water activities',
    ),
    Hotel(
      id: '5',
      name: 'Jaipur Heritage Hotel',
      city: 'Jaipur',
      state: 'Rajasthan',
      country: 'India',
      rating: 4.6,
      price: 3200,
      currency: 'INR',
      imageUrl:
          'https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=800',
      amenities: ['WiFi', 'Traditional Dining', 'Cultural Shows', 'Pool'],
      description: 'Stay in a palace in the Pink City',
    ),
    Hotel(
      id: '6',
      name: 'Kerala Backwater Villa',
      city: 'Alleppey',
      state: 'Kerala',
      country: 'India',
      rating: 4.8,
      price: 4800,
      currency: 'INR',
      imageUrl:
          'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800',
      amenities: ['Houseboat', 'Ayurvedic Spa', 'Nature Tours', 'Restaurant'],
      description: 'Serene backwater experience in God\'s own country',
    ),
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => _onSearchChanged(_searchController.text),
    );
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(searchQuery: query),
        ),
      ).then((_) {
        // Clear the search controller when returning from SearchResultsScreen
        _searchController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a search term'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onSearchChanged(String query) {
    // Debounce to avoid sending too many API requests
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
      // Since we removed suggestions functionality, we don't need to call these methods
      // Just keeping the debounce logic for future implementation
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final hotelProvider = Provider.of<HotelProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MyTravaly Hotels',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        auth.signOut();
                        Navigator.pop(context);
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section with Search
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar using SearchAnchor.
                // We listen to AuthProvider to enable the search bar only when the visitor token is ready.
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    // If the auth provider is not ready, show a disabled search bar.
                    if (!hotelProvider.isReady) {
                      return const SearchBar(
                        leading: Icon(Icons.search),
                        hintText: 'Initializing...',
                        enabled: false,
                      );
                    }
                    // Otherwise, show the fully functional SearchAnchor.
                    return SearchAnchor.bar(
                      barHintText: 'Search hotels, city, state...',
                      searchController: _searchController,
                      onSubmitted: (query) => _performSearch(),
                      suggestionsBuilder: (context, controller) {
                        // Use Provider.of(context) to listen for changes.
                        // This will rebuild the suggestions when the provider updates.
                        final hotelProvider = Provider.of<HotelProvider>(
                          context,
                          listen: false,
                        );

                        if (hotelProvider.isLoadingMore) {
                          return [
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ];
                        }

                        if (controller.text.isEmpty) {
                          return [];
                        }

                        // Since we removed suggestions functionality, just show a simple search message
                        return [
                          ListTile(
                            leading: const Icon(Icons.search),
                            title: Text('Search for "${controller.text}"'),
                            onTap: () {
                              // Close the suggestions view and perform the search
                              controller.closeView(controller.text);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchResultsScreen(
                                    searchQuery: controller.text,
                                  ),
                                ),
                              ).then((_) {
                                // Clear the search controller when returning from SearchResultsScreen
                                _searchController.clear();
                              });
                            },
                          ),
                        ];
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Hotels List Section
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sampleHotels.length + 1, // +1 for header
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Header
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Featured Hotels',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_sampleHotels.length} hotels',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final hotel = _sampleHotels[index - 1];
                return HotelCard(
                  hotel: hotel,
                  onTap: () => _showHotelDetails(context, hotel),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showHotelDetails(BuildContext context, Hotel hotel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (hotel.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      hotel.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.hotel, size: 64),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),

                Text(
                  hotel.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                if (hotel.fullLocation.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hotel.fullLocation,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),

                if (hotel.rating != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          hotel.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          ' / 5.0',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                if (hotel.description != null) ...[
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hotel.description!,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                ],

                if (hotel.amenities != null && hotel.amenities!.isNotEmpty) ...[
                  const Text(
                    'Amenities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: hotel.amenities!.map((amenity) {
                      return Chip(
                        label: Text(amenity),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                if (hotel.price != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Price per night',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          hotel.displayPrice,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Booking ${hotel.name}...'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ...

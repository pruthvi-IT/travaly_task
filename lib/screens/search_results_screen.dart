import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/hotel_provider.dart';
import '../models/hotel.dart';
import '../widgets/hotel_card.dart';
import '../widgets/loading_shimmer.dart';

class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;

  const SearchResultsScreen({super.key, required this.searchQuery});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[SearchResultsScreen] initState - query: ${widget.searchQuery}',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
      debugPrint(
        '[SearchResultsScreen] Starting search for query: ${widget.searchQuery}',
      );
      await hotelProvider.searchHotels(
        query: widget.searchQuery,
        isNewSearch: true,
      );
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() async {
    // Trigger loading when user scrolls to 80% of the list
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final provider = Provider.of<HotelProvider>(context, listen: false);

      debugPrint(
        '[SearchResultsScreen] Scroll at ${_scrollController.position.pixels}/${_scrollController.position.maxScrollExtent}',
      );

      if (!provider.isLoadingMore && provider.hasMore && !provider.isLoading) {
        debugPrint('[SearchResultsScreen] Triggering loadMore()');
        await provider.loadMore(
          query: widget.searchQuery,
        ); // This call is correct
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Results for ${widget.searchQuery}',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [],
      ),
      body: Consumer<HotelProvider>(
        builder: (context, provider, _) {
          debugPrint(
            '[SearchResultsScreen] Building UI - results: ${provider.hotels.length}, isLoading: ${provider.isLoading}, error: ${provider.error}',
          );

          return Column(
            children: [Expanded(child: _buildResultsContent(provider))],
          );
        },
      ),
    );
  }

  Widget _buildResultsContent(HotelProvider provider) {
    // Show error if any
    if (provider.error != null && provider.hotels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error occurred while searching',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  provider.error!.contains('API error')
                      ? 'We\'re having trouble connecting to our servers. Please try again later.'
                      : provider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  //provider.isLoading = true;
                  provider.searchHotels(
                    query: widget.searchQuery,
                    isNewSearch: true,
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading indicator for initial load
    if (provider.isLoading && provider.hotels.isEmpty) {
      debugPrint('[SearchResultsScreen] Showing loading shimmer');
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => const LoadingShimmer(),
      );
    }

    // Show empty state
    if (provider.hotels.isEmpty && !provider.isLoading) {
      debugPrint('[SearchResultsScreen] Showing empty state');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No hotels found for "${widget.searchQuery}"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching with different keywords',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Show results with pagination
    debugPrint(
      '[SearchResultsScreen] Showing ${provider.hotels.length} results',
    );

    return Column(
      children: [
        // Results count header
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              Icon(
                Icons.hotel,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${provider.hotels.length} hotels found',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (provider.hasMore) ...[
                const Spacer(),
                Text(
                  'Scroll for more',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount:
                provider.hotels.length + (provider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Show loading indicator at bottom when loading more
              if (index == provider.hotels.length) {
                debugPrint(
                  '[SearchResultsScreen] Showing loading more indicator',
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          'Loading more hotels...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final hotel = provider.hotels[index];
              return HotelCard(
                hotel: hotel,
                onTap: () => _showHotelDetails(context, hotel),
              );
            },
          ),
        ),

        // No manual load more button - using infinite scroll
      ],
    );
  }
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

              // Hotel image with improved error handling
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hotel.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: hotel.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          debugPrint(
                            'Detail image error: $error for URL: ${hotel.imageUrl}',
                          );
                          return Container(
                            height: 200,
                            color: Colors.grey.shade200,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.hotel,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image not available',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hotel,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No image available',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
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
                Text(hotel.description!),
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
            ],
          ),
        );
      },
    ),
  );
}

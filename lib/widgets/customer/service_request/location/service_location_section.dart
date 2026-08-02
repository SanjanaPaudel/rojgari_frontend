import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/map_config.dart';
import '../../../../models/service_request/selected_service_location.dart';
import '../../../../services/location/location_service.dart';
import '../../../../services/location/open_street_map_search_service.dart';
import 'location_error_view.dart';
import 'map_center_pin.dart';
import 'selected_address_card.dart';
import '../service_request_notification.dart';

enum _LocationViewState {
  checking,
  serviceDisabled,
  permissionRequired,
  permissionDenied,
  permissionBlocked,
  loading,
  ready,
  error,
}

class ServiceLocationSection extends StatefulWidget {
  const ServiceLocationSection({
    required this.onLocationSelected,
    this.initialLocation,
    this.locationService = const LocationService(),
    this.onAddressResolvingChanged,
    super.key,
  });

  final ValueChanged<SelectedServiceLocation> onLocationSelected;
  final SelectedServiceLocation? initialLocation;
  final LocationService locationService;
  final ValueChanged<bool>? onAddressResolvingChanged;

  @override
  State<ServiceLocationSection> createState() => _ServiceLocationSectionState();
}

class _ServiceLocationSectionState extends State<ServiceLocationSection>
    with WidgetsBindingObserver {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  late final OpenStreetMapSearchService _searchService;

  _LocationViewState _state = _LocationViewState.checking;
  SelectedServiceLocation? _selected;
  LatLng? _cameraTarget;
  LatLng? _currentGpsTarget;
  List<LocationSearchResult> _searchResults = const [];
  String _errorMessage = 'Unable to load location.';
  String? _displayAddress;
  bool _isMapMoving = false;
  bool _isSearching = false;
  bool _isMapExpanded = false;
  bool _returningFromSettings = false;
  bool _ignoreNextMoveEnd = false;
  bool _isResolvingAddress = false;
  int _addressLookupGeneration = 0;
  int _searchGeneration = 0;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchService = OpenStreetMapSearchService();
    _selected = widget.initialLocation;
    _displayAddress = widget.initialLocation?.landmark;
    if (_selected != null) {
      _cameraTarget = LatLng(_selected!.latitude, _selected!.longitude);
    }
    _checkAvailability();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _returningFromSettings) {
      _returningFromSettings = false;
      _checkAvailability();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchService.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    if (mounted) setState(() => _state = _LocationViewState.checking);
    try {
      final serviceEnabled = await widget.locationService
          .isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        setState(() => _state = _LocationViewState.serviceDisabled);
        return;
      }
      final permission = await widget.locationService.checkPermission();
      if (!mounted) return;
      switch (permission) {
        case AppLocationPermission.granted:
          // A prior selection (e.g. reopening via "Change" after already
          // confirming a location) takes precedence over auto-fetching GPS —
          // initState already seeded _selected/_cameraTarget from it. Only
          // fetch the current position when there's nothing to preserve.
          if (widget.initialLocation != null) {
            setState(() => _state = _LocationViewState.ready);
            return;
          }
          await _loadCurrentLocation();
          return;
        case AppLocationPermission.blocked:
          setState(() => _state = _LocationViewState.permissionBlocked);
          return;
        case AppLocationPermission.denied:
          setState(() => _state = _LocationViewState.permissionDenied);
          return;
        case AppLocationPermission.notRequested:
          setState(() => _state = _LocationViewState.permissionRequired);
          return;
      }
    } catch (error) {
      if (mounted) {
        _setError('Unable to check location settings.');
      }
    }
  }

  Future<void> _requestPermission() async {
    try {
      final permission = await widget.locationService.requestPermission();
      if (!mounted) return;
      switch (permission) {
        case AppLocationPermission.granted:
          if (widget.initialLocation != null) {
            setState(() => _state = _LocationViewState.ready);
            return;
          }
          await _loadCurrentLocation();
          return;
        case AppLocationPermission.blocked:
          setState(() => _state = _LocationViewState.permissionBlocked);
          return;
        case AppLocationPermission.denied:
        case AppLocationPermission.notRequested:
          setState(() => _state = _LocationViewState.permissionDenied);
          return;
      }
    } catch (error) {
      if (mounted) {
        _setError('Unable to request location permission.');
      }
    }
  }

  Future<void> _openLocationSettings() async {
    _returningFromSettings = true;
    try {
      await widget.locationService.openLocationSettings();
    } catch (error) {
      if (mounted) {
        _setError('Unable to open location settings.');
      }
    }
  }

  Future<void> _openAppSettings() async {
    _returningFromSettings = true;
    try {
      await widget.locationService.openAppSettings();
    } catch (error) {
      if (mounted) _setError('Unable to open app settings.');
    }
  }

  Future<void> _loadCurrentLocation() async {
    // The map only exists once _state is already `ready` — this method also
    // runs for the very first location fetch (from _checkAvailability,
    // before FlutterMap has ever built), when there's no MapController to
    // move yet. initialCenter already handles that first-render case.
    final mapAlreadyOnScreen = _state == _LocationViewState.ready;

    if (mounted) {
      setState(() => _state = _LocationViewState.loading);
    }
    try {
      final current = await widget.locationService.getCurrentLocation();
      if (!mounted) return;
      final target = LatLng(current.latitude, current.longitude);
      final next = SelectedServiceLocation(
        latitude: current.latitude,
        longitude: current.longitude,
        accuracyMeters: current.accuracyMeters,
        source: 'gps',
      );
      setState(() {
        _cameraTarget = target;
        _currentGpsTarget = target;
        _selected = next;
        _displayAddress = null;
        _state = _LocationViewState.ready;
        _isMapMoving = false;
      });
      widget.onLocationSelected(next);
      if (mapAlreadyOnScreen) {
        _ignoreNextMoveEnd = true;
        _mapController.move(target, 17);
      }
      unawaited(_resolveAddress(next));
    } on LocationServiceException catch (error) {
      if (mounted) _setError(error.message);
    } catch (error) {
      if (mounted) _setError('Current location is unavailable.');
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _cameraTarget = camera.center;
    if (hasGesture && !_isMapMoving && mounted) {
      setState(() {
        _isMapMoving = true;
        _searchResults = const [];
      });
    }
  }

  void _onMapEvent(MapEvent event) {
    if (event is! MapEventMoveEnd) return;
    if (_ignoreNextMoveEnd) {
      _ignoreNextMoveEnd = false;
      return;
    }
    final target = _cameraTarget ?? event.camera.center;
    final next = SelectedServiceLocation(
      latitude: target.latitude,
      longitude: target.longitude,
      source: 'map',
    );
    setState(() {
      _selected = next;
      _displayAddress = null;
      _isMapMoving = false;
    });
    widget.onLocationSelected(next);
    unawaited(_resolveAddress(next));
  }

  void _onSearchQueryChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    final generation = ++_searchGeneration;
    if (query.length < 3) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = const [];
        });
      }
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 650),
      () => unawaited(
        _performSearch(
          query: query,
          generation: generation,
          showMessages: false,
        ),
      ),
    );
  }

  void _submitSearch() {
    _searchDebounce?.cancel();
    final generation = ++_searchGeneration;
    unawaited(
      _performSearch(
        query: _searchController.text.trim(),
        generation: generation,
        showMessages: true,
      ),
    );
  }

  Future<void> _performSearch({
    required String query,
    required int generation,
    required bool showMessages,
  }) async {
    if (showMessages) FocusScope.of(context).unfocus();
    if (query.length < 3) {
      if (showMessages) _showMessage('Enter at least 3 characters to search.');
      return;
    }
    setState(() {
      _isSearching = true;
      _searchResults = const [];
    });
    try {
      final results = await _searchService.search(query);
      if (!mounted || generation != _searchGeneration) return;
      setState(() => _searchResults = results);
      if (results.isEmpty && showMessages) {
        _showMessage('No matching location found. Try a nearby landmark.');
      }
    } on LocationSearchException catch (error) {
      if (mounted && generation == _searchGeneration && showMessages) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted && generation == _searchGeneration && showMessages) {
        _showMessage('Location search is unavailable. Please try again.');
      }
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectSearchResult(LocationSearchResult result) {
    _searchDebounce?.cancel();
    _searchGeneration++;
    FocusScope.of(context).unfocus();
    final target = LatLng(result.latitude, result.longitude);
    final next = SelectedServiceLocation(
      latitude: result.latitude,
      longitude: result.longitude,
      landmark: result.displayName,
      source: 'search',
    );
    setState(() {
      _cameraTarget = target;
      _selected = next;
      _displayAddress = result.displayName;
      _searchController.text = result.displayName;
      _searchResults = const [];
      _isMapMoving = false;
    });
    widget.onLocationSelected(next);
    _setAddressResolving(false);
    _ignoreNextMoveEnd = true;
    _mapController.move(target, 17);
  }

  Future<void> _resolveAddress(SelectedServiceLocation location) async {
    final generation = ++_addressLookupGeneration;
    _setAddressResolving(true);
    try {
      final result = await _searchService.reverse(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      if (!mounted || generation != _addressLookupGeneration) return;
      final displayName = result?.displayName;
      final resolved = displayName == null
          ? location
          : location.copyWith(landmark: displayName);
      setState(() {
        _selected = resolved;
        _displayAddress = displayName;
      });
      widget.onLocationSelected(resolved);
    } catch (_) {
      if (!mounted || generation != _addressLookupGeneration) return;
      setState(() => _displayAddress = null);
    } finally {
      if (mounted && generation == _addressLookupGeneration) {
        _setAddressResolving(false);
      }
    }
  }

  void _setAddressResolving(bool value) {
    if (_isResolvingAddress == value) return;
    _isResolvingAddress = value;
    widget.onAddressResolvingChanged?.call(value);
  }

  void _showMessage(String message) {
    ServiceRequestNotifier.show(context, message: message);
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
      _state = _LocationViewState.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _LocationViewState.checking:
      case _LocationViewState.loading:
        return _LoadingLocationCard(
          label: _state == _LocationViewState.checking
              ? 'Checking location access...'
              : 'Getting your current location...',
        );
      case _LocationViewState.serviceDisabled:
        return LocationErrorView(
          title: 'Location is turned off',
          message: 'Turn on location to select your service address.',
          actionLabel: 'Turn on location',
          onAction: _openLocationSettings,
        );
      case _LocationViewState.permissionRequired:
        return LocationErrorView(
          title: 'Allow location access',
          message: 'Location access helps detect where the worker should come.',
          actionLabel: 'Allow location access',
          onAction: _requestPermission,
          icon: Icons.location_searching_rounded,
        );
      case _LocationViewState.permissionDenied:
        return LocationErrorView(
          title: 'Location permission denied',
          message:
              'Allow access to automatically detect your current location.',
          actionLabel: 'Try again',
          onAction: _requestPermission,
        );
      case _LocationViewState.permissionBlocked:
        return LocationErrorView(
          title: 'Location permission is blocked',
          message: 'Enable it from app settings.',
          actionLabel: 'Open app settings',
          onAction: _openAppSettings,
        );
      case _LocationViewState.error:
        return LocationErrorView(
          title: 'Location unavailable',
          message: _errorMessage,
          actionLabel: 'Retry',
          onAction: _checkAvailability,
          icon: Icons.sync_problem_outlined,
        );
      case _LocationViewState.ready:
        return _buildReadyState(context);
    }
  }

  Widget _buildReadyState(BuildContext context) {
    final selected = _selected;
    final target = _cameraTarget;
    if (selected == null || target == null) {
      return LocationErrorView(
        title: 'Location unavailable',
        message: 'No valid service location was selected.',
        actionLabel: 'Retry',
        onAction: _checkAvailability,
      );
    }

    final screenHeight = MediaQuery.sizeOf(context).height;
    final normalHeight = (screenHeight * .48).clamp(350.0, 480.0).toDouble();
    final mapHeight = _isMapExpanded
        ? (screenHeight - 115).clamp(520.0, 850.0).toDouble()
        : normalHeight;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: mapHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: target,
                    initialZoom: 17,
                    minZoom: 3,
                    maxZoom: 19,
                    onPositionChanged: _onPositionChanged,
                    onMapEvent: _onMapEvent,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapConfig.openStreetMapTileUrl,
                      userAgentPackageName: MapConfig.userAgentPackageName,
                      maxZoom: 19,
                    ),
                    if (_currentGpsTarget != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentGpsTarget!,
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF4285F4),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const MapCenterPin(),
                Positioned(
                  right: 12,
                  top: 72,
                  child: _MapControlButton(
                    tooltip: _isMapExpanded
                        ? 'Exit full screen'
                        : 'Full screen',
                    icon: _isMapExpanded
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    onPressed: () {
                      setState(() => _isMapExpanded = !_isMapExpanded);
                    },
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 14,
                  child: _MapControlButton(
                    tooltip: 'Use current location',
                    icon: Icons.my_location_rounded,
                    onPressed: _loadCurrentLocation,
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .88),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      child: Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 9, color: Color(0xFF555266)),
                      ),
                    ),
                  ),
                ),
                if (_isMapMoving)
                  const Positioned(
                    left: 12,
                    bottom: 30,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: _LocationSearchOverlay(
                    controller: _searchController,
                    isSearching: _isSearching,
                    results: _searchResults,
                    onQueryChanged: _onSearchQueryChanged,
                    onSearch: _submitSearch,
                    onResultSelected: _selectSearchResult,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!_isMapExpanded) ...[
          const SizedBox(height: 12),
          SelectedAddressCard(
            location: selected,
            displayAddress: _displayAddress,
            isResolving: _isResolvingAddress,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _loadCurrentLocation,
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: const Text('Use current location'),
            ),
          ),
        ],
      ],
    );
  }
}

class _LocationSearchOverlay extends StatelessWidget {
  const _LocationSearchOverlay({
    required this.controller,
    required this.isSearching,
    required this.results,
    required this.onQueryChanged,
    required this.onSearch,
    required this.onResultSelected,
  });

  final TextEditingController controller;
  final bool isSearching;
  final List<LocationSearchResult> results;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSearch;
  final ValueChanged<LocationSearchResult> onResultSelected;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Material(
        color: Colors.white,
        elevation: 5,
        borderRadius: BorderRadius.circular(14),
        child: TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onChanged: onQueryChanged,
          onSubmitted: (_) => onSearch(),
          decoration: InputDecoration(
            hintText: 'Search area, road or landmark',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: isSearching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Search location',
                    onPressed: onSearch,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      if (results.isNotEmpty) ...[
        const SizedBox(height: 6),
        Material(
          color: Colors.white,
          elevation: 6,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 210),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: results.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final result = results[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    result.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  onTap: () => onResultSelected(result),
                );
              },
            ),
          ),
        ),
      ],
    ],
  );
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 4,
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: AppColors.primary,
      icon: Icon(icon),
    ),
  );
}

class _LoadingLocationCard extends StatelessWidget {
  const _LoadingLocationCard({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 180,
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2DEEB)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(color: AppColors.grey, fontSize: 12),
        ),
      ],
    ),
  );
}

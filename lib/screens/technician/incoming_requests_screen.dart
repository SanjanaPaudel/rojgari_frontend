import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../models/incoming_request_model.dart';
import '../../services/incoming_request_service.dart';
import '../../widgets/technician/incoming_request_card.dart';

// "All Incoming Requests" — the View All destination from the technician
// home screen's "New requests near you" section.
//
// Backed by GET /api/auth/worker/incoming-requests/ via
// IncomingRequestService.
//
// KNOWN BACKEND LIMITATION:
// That endpoint returns only offers with status="pending" and sends no status
// field, so every request loads as `isNew`. The Viewed and Offered tabs will
// therefore always be empty until the backend tracks and returns a status.

enum _RequestFilter { all, isNew, viewed, offered }

class IncomingRequestsScreen extends StatefulWidget {
  const IncomingRequestsScreen({super.key});

  @override
  State<IncomingRequestsScreen> createState() => _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState extends State<IncomingRequestsScreen> {
  final IncomingRequestService _service = IncomingRequestService();

  _RequestFilter _activeFilter = _RequestFilter.all;
  List<IncomingRequest> _requests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final requests = await _service.fetchIncomingRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        // ApiService throws a session-expired Exception and navigates to the
        // login screen itself; the message is shown here only if this screen
        // is somehow still mounted.
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  int _countFor(_RequestFilter filter) => switch (filter) {
    _RequestFilter.all => _requests.length,
    _RequestFilter.isNew => _requests
        .where((r) => r.status == IncomingRequestStatus.isNew)
        .length,
    _RequestFilter.viewed => _requests
        .where((r) => r.status == IncomingRequestStatus.viewed)
        .length,
    _RequestFilter.offered => _requests
        .where((r) => r.status == IncomingRequestStatus.offered)
        .length,
  };

  List<IncomingRequest> get _visibleRequests => switch (_activeFilter) {
    _RequestFilter.all => _requests,
    _RequestFilter.isNew => _requests
        .where((r) => r.status == IncomingRequestStatus.isNew)
        .toList(),
    _RequestFilter.viewed => _requests
        .where((r) => r.status == IncomingRequestStatus.viewed)
        .toList(),
    _RequestFilter.offered => _requests
        .where((r) => r.status == IncomingRequestStatus.offered)
        .toList(),
  };

  @override
  Widget build(BuildContext context) {
    final visible = _visibleRequests;

    return Scaffold(
      backgroundColor: const Color(0xffFAF9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xffFAF9FE),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff171725)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Incoming Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xff171725),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
            child: OutlinedButton.icon(
              onPressed: () {
                // NAVIGATION PLACE:
                // Filter options are not specified yet. Wire this to the
                // filter sheet once the criteria are defined.
                debugPrint('Filter clicked');
              },
              icon: const Icon(Icons.filter_list, size: 18),
              label: const Text(
                'Filter',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: Color(0xffD8CCFB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: _OfferInfoBanner(),
          ),
          const SizedBox(height: 14),
          _FilterTabs(
            activeFilter: _activeFilter,
            countFor: _countFor,
            onChanged: (filter) => setState(() => _activeFilter = filter),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xffECE9F3)),
          Expanded(child: _buildBody(visible)),
        ],
      ),
    );
  }

  Widget _buildBody(List<IncomingRequest> visible) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _loadRequests);
    }

    // RefreshIndicator needs a scrollable child, so the empty state is placed
    // inside a scroll view that always overscrolls.
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadRequests,
      child: visible.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                _EmptyState(),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final request = visible[index];
                return IncomingRequestCard(
                  request: request,
                  onTap: () {
                    // NAVIGATION PLACE:
                    // GET /api/auth/worker/request/<offer_id>/ backs the
                    // detail page. Push it here with request.id once built.
                    debugPrint('${request.title} clicked');
                  },
                );
              },
            ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 46,
              color: Color(0xffBFC4D2),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xff6E7191),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: Color(0xffD8CCFB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferInfoBanner extends StatelessWidget {
  const _OfferInfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xffF1ECFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Set your service charge (per hour) and estimated time.',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Customer will review and accept your offer.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xff6E7191),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.activeFilter,
    required this.countFor,
    required this.onChanged,
  });

  final _RequestFilter activeFilter;
  final int Function(_RequestFilter) countFor;
  final ValueChanged<_RequestFilter> onChanged;

  static const Map<_RequestFilter, String> _labels = {
    _RequestFilter.all: 'All Requests',
    _RequestFilter.isNew: 'New',
    _RequestFilter.viewed: 'Viewed',
    _RequestFilter.offered: 'Offered',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          for (final filter in _RequestFilter.values)
            _FilterTab(
              label: _labels[filter]!,
              count: countFor(filter),
              isActive: filter == activeFilter,
              onTap: () => onChanged(filter),
            ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : const Color(0xff6E7191);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xffEDE4FF)
                    : const Color(0xffF1F1F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 46, color: Color(0xffBFC4D2)),
          SizedBox(height: 10),
          Text(
            'No requests here yet.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xff6E7191),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

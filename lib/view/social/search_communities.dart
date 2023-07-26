import 'dart:async';

import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/view/social/community_feed.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodel/community_feed_viewmodel.dart';

class SearchCommunitiesScreen extends StatefulWidget {
  const SearchCommunitiesScreen({Key? key}) : super(key: key);

  @override
  _SearchCommunitiesScreenState createState() =>
      _SearchCommunitiesScreenState();
}

class _SearchCommunitiesScreenState extends State<SearchCommunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<AmityCommunity> _communities = [];
  String? _pageToken;
  bool _isLoading = false;
  String? _error;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _searchCommunities(String keyword) async {
    if (keyword.isEmpty || keyword == '') {
      setState(() {
        _communities.clear();
      });
      return;
    }
    try {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        setState(() {
          _isLoading = true;
          _error = null;
        });
        final response = await AmitySocialClient.newCommunityRepository()
            .getCommunities()
            .withKeyword(keyword)
            .getPagingData(token: _pageToken, limit: 20);

        setState(() {
          _communities = response.data;
          _pageToken = response.token;
          _isLoading = false;
        });
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _error = 'Error fetching communities. Please try again.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading) {
        _searchCommunities(_searchController.text);
      }
    }
  }

  void _navigateToCommunityDetails(AmityCommunity community) {
    // Navigator.of(context).push(MaterialPageRoute(
    //   builder: (context) =>  CommunityScreen(
    //     community: community,
    //     isFromFeed: false,
    //   ),
    // ));
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
              create: (context) => CommuFeedVM(),
              child: CommunityScreen(
                community: community,
        isFromFeed: false,
              ),
            )));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Communities'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchCommunities,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                  ),
                ),
              ),
              if (_isLoading)
                Positioned(
                  right: 12,
                  top: 20,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 3.0),
                  ),
                ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _communities.length,
              itemBuilder: (context, index) {
                final community = _communities[index];
                return GestureDetector(
                  onTap: () => _navigateToCommunityDetails(community),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(
                            community.avatarImage?.fileUrl ??
                                'https://images.unsplash.com/photo-1598128558393-70ff21433be0?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=978&q=80',
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          community.displayName ?? 'displayname not found',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

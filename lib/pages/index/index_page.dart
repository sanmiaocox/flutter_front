import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../data/home_mock_data.dart';
import 'index_feed_tab.dart';
import 'index_ranking_tab.dart';
import 'index_events_tab.dart';
import 'index_favorites_tab.dart';
import 'search/search_page.dart';
import 'movie_detail/movie_detail_page.dart';
import 'event_detail/event_detail_page.dart';
import 'feed_detail/feed_detail_page.dart';

/// 主页（底部导航第一个）：顶部搜索 + Tab（动态/热门榜单/热门活动/我的收藏）+ 内容区。
class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
  }

  void _openMovieDetail(int movieId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MovieDetailPage(movieId: movieId)),
    );
  }

  void _openEventDetail(int eventId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventDetailPage(eventId: eventId)),
    );
  }

  void _openFeedDetail(FeedItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FeedDetailPage(feed: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: AppTheme.capriBlue,
              foregroundColor: AppTheme.lycheeWhite,
              elevation: 0,
              expandedHeight: 0,
              toolbarHeight: 56,
              title: null,
              flexibleSpace: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: InkWell(
                    onTap: _openSearch,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 22,
                            color: AppTheme.mutedForeground,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '搜索...',
                            style: TextStyle(
                              color: AppTheme.mutedForeground,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.capriBlue,
                  unselectedLabelColor: AppTheme.mutedForeground,
                  indicatorColor: AppTheme.softPeach,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontSize: 12, height: 1.0),
                  unselectedLabelStyle: const TextStyle(fontSize: 12, height: 1.0),
                  // 新增：小屏自动滚动，避免横向溢出
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rss_feed, size: 18),
                          SizedBox(width: 6),
                          Text('动态'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up, size: 18),
                          SizedBox(width: 6),
                          Text('热门榜单'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 18),
                          SizedBox(width: 6),
                          Text('热门活动'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite, size: 18),
                          SizedBox(width: 6),
                          Text('我的收藏'),
                        ],
                      ),
                    ),
                  ],
                ),
                color: AppTheme.lycheeWhite,
                borderColor: AppTheme.muted.withValues(alpha: 0.3),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            IndexFeedTab(
              onTapMovie: _openMovieDetail,
              onTapComment: _openFeedDetail,
            ),
            IndexRankingTab(
              onTapMovie: _openMovieDetail,
              onTapCarousel: (id) => _openMovieDetail(id),
              onMoreRanking: () {},
              onMoreNewReleases: () {},
            ),
            IndexEventsTab(
              onTapEvent: _openEventDetail,
              onJoin: _openEventDetail,
            ),
            IndexFavoritesTab(onTapMovie: _openMovieDetail),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar, {required this.color, required this.borderColor});

  final TabBar tabBar;
  final Color color;
  final Color borderColor;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: color,
      child: Column(
        children: [
          tabBar,
          Divider(height: 1, color: borderColor),
        ],
      ),
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  double get minExtent => tabBar.preferredSize.height + 1;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

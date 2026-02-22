/// 主页 Mock 数据（死数据），与 figma 设计一致，仅用于开发与 UI 调试。
/// 对接后端时：只替换本文件中 [HomeMockData] 的数据来源为 API 请求，或删除本文件改由
/// 接口返回同结构数据；页面与组件只依赖下方模型类，便于直接替换为接口数据。

class FeedItem {
  final int id;
  final String userName;
  final String userAvatar;
  final String timeAgo;
  final String content;
  final String? movieTitle;
  final String? moviePoster;
  final double? rating;
  final int likes;
  final int comments;
  final int shares;

  const FeedItem({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.timeAgo,
    required this.content,
    this.movieTitle,
    this.moviePoster,
    this.rating,
    required this.likes,
    required this.comments,
    required this.shares,
  });
}

class CarouselMovie {
  final int id;
  final String title;
  final String imageUrl;
  final double rating;
  final String description;

  const CarouselMovie({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.description,
  });
}

class RankingMovie {
  final int id;
  final int rank;
  final String title;
  final String imageUrl;
  final double rating;
  final int change;
  final String genre;

  const RankingMovie({
    required this.id,
    required this.rank,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.change,
    required this.genre,
  });
}

class EventItem {
  final int id;
  final String title;
  final String imageUrl;
  final String date;
  final String location;
  final int participants;
  final String type;

  const EventItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.date,
    required this.location,
    required this.participants,
    required this.type,
  });
}

class MovieCardItem {
  final int id;
  final String title;
  final String imageUrl;
  final double rating;
  final String year;
  final String genre;

  const MovieCardItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.year,
    required this.genre,
  });
}

abstract class HomeMockData {
  static const _base = 'https://images.unsplash.com/photo-';
  static const _unsplashParams =
      'crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=400';

  static List<FeedItem> get feedList => [
        FeedItem(
          id: 1,
          userName: '电影爱好者小王',
          userAvatar: '$_base 1763536529823-953ff472bf35?$_unsplashParams',
          timeAgo: '2小时前',
          content:
              '刚看完这部科幻大片，视觉效果太震撼了！强烈推荐给喜欢科幻的朋友们 🎬✨',
          movieTitle: '星际穿越',
          moviePoster: '$_base 1761948245703-cbf27a3e7502?$_unsplashParams',
          rating: 9.3,
          likes: 234,
          comments: 45,
          shares: 23,
        ),
        FeedItem(
          id: 2,
          userName: '影评人李华',
          userAvatar: '$_base 1569913486515-b74bf7751574?$_unsplashParams',
          timeAgo: '5小时前',
          content:
              '今天参加了首映礼，这部动作片节奏紧凑，打斗场面设计得非常精彩！导演真的太厉害了 👏',
          movieTitle: '疾速追杀4',
          moviePoster: '$_base 1765510296004-614b6cc204da?$_unsplashParams',
          rating: 8.7,
          likes: 567,
          comments: 89,
          shares: 34,
        ),
        FeedItem(
          id: 3,
          userName: '张明',
          userAvatar: '$_base 1563481911853-c14860cd6947?$_unsplashParams',
          timeAgo: '1天前',
          content:
              '周末和朋友一起去看了这部奇幻电影，特效制作真的太用心了，每一帧都是壁纸级别！',
          movieTitle: '奇幻星球',
          moviePoster: '$_base 1763244734635-72b34a167bd5?$_unsplashParams',
          rating: 7.9,
          likes: 189,
          comments: 32,
          shares: 15,
        ),
      ];

  static List<CarouselMovie> get carouselMovies => [
        CarouselMovie(
          id: 1,
          title: '星际穿越',
          imageUrl: '$_base 1761948245703-cbf27a3e7502?$_unsplashParams',
          rating: 9.3,
          description: '一场超越时空的冒险，探索宇宙的奥秘与人类的未来。',
        ),
        CarouselMovie(
          id: 2,
          title: '疾速追杀4',
          imageUrl: '$_base 1765510296004-614b6cc204da?$_unsplashParams',
          rating: 8.7,
          description: '最精彩的动作巨制，惊险刺激的追逐与战斗场面。',
        ),
        CarouselMovie(
          id: 3,
          title: '奇幻星球',
          imageUrl: '$_base 1763244734635-72b34a167bd5?$_unsplashParams',
          rating: 7.9,
          description: '充满想象力的奇幻世界，带你进入梦幻般的冒险旅程。',
        ),
      ];

  static List<RankingMovie> get weeklyRanking => [
        RankingMovie(
            id: 1, rank: 1, title: '星际穿越', imageUrl: '$_base 1761948245703-cbf27a3e7502?$_unsplashParams', rating: 9.3, change: 2, genre: '科幻'),
        RankingMovie(
            id: 2, rank: 2, title: '疾速追杀4', imageUrl: '$_base 1765510296004-614b6cc204da?$_unsplashParams', rating: 8.7, change: -1, genre: '动作'),
        RankingMovie(
            id: 3, rank: 3, title: '彩色梦境', imageUrl: '$_base 1769311698182-753ea8d1eda0?$_unsplashParams', rating: 8.8, change: 1, genre: '动画'),
        RankingMovie(
            id: 4, rank: 4, title: '深夜惊魂', imageUrl: '$_base 1653853301139-f57c5fdc069a?$_unsplashParams', rating: 8.2, change: 0, genre: '恐怖'),
        RankingMovie(
            id: 5, rank: 5, title: '奇幻星球', imageUrl: '$_base 1763244734635-72b34a167bd5?$_unsplashParams', rating: 7.9, change: -2, genre: '奇幻'),
      ];

  static List<EventItem> get events => [
        EventItem(
          id: 1,
          title: '第76届戛纳国际电影节展映',
          imageUrl: '$_base 1741569409778-e7a23b87cfd7?$_unsplashParams',
          date: '2026年3月15日',
          location: '北京国际影城',
          participants: 1250,
          type: '电影节',
        ),
        EventItem(
          id: 2,
          title: '经典科幻电影回顾展',
          imageUrl: '$_base 1761948245703-cbf27a3e7502?$_unsplashParams',
          date: '2026年3月20日',
          location: '上海大光明电影院',
          participants: 680,
          type: '主题展映',
        ),
        EventItem(
          id: 3,
          title: '导演见面会：探索电影艺术',
          imageUrl: '$_base 1765510296004-614b6cc204da?$_unsplashParams',
          date: '2026年3月25日',
          location: '深圳影城',
          participants: 320,
          type: '见面会',
        ),
        EventItem(
          id: 4,
          title: '动画电影嘉年华',
          imageUrl: '$_base 1769311698182-753ea8d1eda0?$_unsplashParams',
          date: '2026年4月1日',
          location: '广州太古汇影城',
          participants: 890,
          type: '嘉年华',
        ),
      ];

  static List<MovieCardItem> get favoriteMovies => [
        MovieCardItem(
          id: 1,
          title: '星际穿越',
          imageUrl: '$_base 1761948245703-cbf27a3e7502?$_unsplashParams',
          rating: 9.3,
          year: '2014',
          genre: '科幻',
        ),
        MovieCardItem(
          id: 2,
          title: '疾速追杀4',
          imageUrl: '$_base 1765510296004-614b6cc204da?$_unsplashParams',
          rating: 8.7,
          year: '2023',
          genre: '动作',
        ),
        MovieCardItem(
          id: 3,
          title: '彩色梦境',
          imageUrl: '$_base 1769311698182-753ea8d1eda0?$_unsplashParams',
          rating: 8.8,
          year: '2024',
          genre: '动画',
        ),
      ];
}

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
  final int? movieId;

  const FeedItem({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.timeAgo,
    required this.content,
    this.movieTitle,
    this.moviePoster,
    this.rating,
    this.movieId,
  });
}

class FeedEngagement {
  int likes;
  int shares;

  FeedEngagement({
    required this.likes,
    required this.shares,
  });
}

class CommentItem {
  final int id;
  final String userName;
  final String userAvatar;
  final String content;
  final String timeAgo;
  final int likes;

  const CommentItem({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.timeAgo,
    required this.likes,
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

class MovieDetail {
  final int id;
  final String title;
  final String originalTitle;
  final List<String> aliases;
  final String posterUrl;
  final List<String> posterUrls; // 多张海报图片
  final double rating;
  final String ratingSource;
  final String releaseDate;
  final String? episodes;
  final List<String> genres;
  final String region;
  final List<String> languages;
  final List<String> directors;
  final List<String> actors;
  final String synopsis;
  final List<ViewingParty> viewingParties;
  final ExternalReviews externalReviews;

  const MovieDetail({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.aliases,
    required this.posterUrl,
    required this.posterUrls,
    required this.rating,
    required this.ratingSource,
    required this.releaseDate,
    this.episodes,
    required this.genres,
    required this.region,
    required this.languages,
    required this.directors,
    required this.actors,
    required this.synopsis,
    required this.viewingParties,
    required this.externalReviews,
  });
}

class ViewingParty {
  final int id;
  final String title;
  final String date;
  final String location;
  final int participants;
  final int maxParticipants;

  const ViewingParty({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.participants,
    required this.maxParticipants,
  });
}

class ExternalReviews {
  final String? doubanUrl;
  final String? zhihuUrl;
  final String? imdbUrl;
  final String? rottenTomatoesUrl;
  final String? tmdbUrl;

  const ExternalReviews({
    this.doubanUrl,
    this.zhihuUrl,
    this.imdbUrl,
    this.rottenTomatoesUrl,
    this.tmdbUrl,
  });
}

abstract class HomeMockData {
  static const _base = 'https://images.unsplash.com/photo-';
  static const _unsplashParams =
      'crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=400';

  /// Mock：动态互动数据唯一数据源（点赞/转发统计）
  static final Map<int, FeedEngagement> _engagementByFeedId = {
    1: FeedEngagement(likes: 234, shares: 23),
    2: FeedEngagement(likes: 567, shares: 34),
    3: FeedEngagement(likes: 189, shares: 15),
  };

  /// Mock：评论列表唯一数据源（评论数 = 列表长度）
  static final Map<int, List<CommentItem>> _commentsByFeedId = {
    1: [
      CommentItem(
        id: 1,
        userName: '影迷小李',
        userAvatar: '$_base 1569913486515-b74bf7751574?$_unsplashParams',
        content: '我也超级喜欢这部电影！特效真的太棒了，尤其是黑洞那段😍',
        timeAgo: '1小时前',
        likes: 23,
      ),
      CommentItem(
        id: 2,
        userName: '电影发烧友',
        userAvatar: '$_base 1563481911853-c14860cd6947?$_unsplashParams',
        content: '诺兰的作品从来不会让人失望，这部更是巅峰之作！',
        timeAgo: '2小时前',
        likes: 45,
      ),
      CommentItem(
        id: 3,
        userName: '科幻爱好者',
        userAvatar: '$_base 1763536529823-953ff472bf35?$_unsplashParams',
        content: '时间膨胀的设定太精彩了，看完之后还在思考里面的科学原理。',
        timeAgo: '3小时前',
        likes: 12,
      ),
    ],
    2: [
      CommentItem(
        id: 1,
        userName: '动作片粉丝',
        userAvatar: '$_base 1569913486515-b74bf7751574?$_unsplashParams',
        content: '基努里维斯的动作戏真的是越来越厉害了！',
        timeAgo: '30分钟前',
        likes: 67,
      ),
      CommentItem(
        id: 2,
        userName: '电影评论家',
        userAvatar: '$_base 1763536529823-953ff472bf35?$_unsplashParams',
        content: '这一部比前作更加精彩，打斗场面设计得非常用心👍',
        timeAgo: '1小时前',
        likes: 34,
      ),
    ],
    3: [
      CommentItem(
        id: 1,
        userName: '奇幻迷',
        userAvatar: '$_base 1563481911853-c14860cd6947?$_unsplashParams',
        content: '画面真的美到窒息，每一帧都想截图当壁纸！',
        timeAgo: '5小时前',
        likes: 28,
      ),
    ],
  };

  static FeedEngagement engagementForFeed(int feedId) {
    return _engagementByFeedId.putIfAbsent(
      feedId,
      () => FeedEngagement(likes: 0, shares: 0),
    );
  }

  static int likeCountForFeed(int feedId) => engagementForFeed(feedId).likes;

  static int shareCountForFeed(int feedId) => engagementForFeed(feedId).shares;

  static int commentCountForFeed(int feedId) =>
      _commentsByFeedId[feedId]?.length ?? 0;

  /// 返回不可修改视图，避免页面误改底层 mock 数据。
  static List<CommentItem> commentsForFeed(int feedId) =>
      List.unmodifiable(_commentsByFeedId[feedId] ?? const []);

  static void addLike(int feedId) {
    final e = engagementForFeed(feedId);
    e.likes += 1;
  }

  static void removeLike(int feedId) {
    final e = engagementForFeed(feedId);
    if (e.likes > 0) e.likes -= 1;
  }

  static void addComment(int feedId, CommentItem comment) {
    final list = _commentsByFeedId.putIfAbsent(feedId, () => <CommentItem>[]);
    list.insert(0, comment);
  }

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
          movieId: 1,
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
          movieId: 2,
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
          movieId: 3,
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

  /// Mock：电影详情数据库（按 ID 存储）
  static final Map<int, MovieDetail> _movieDetailsById = {
    1: MovieDetail(
      id: 1,
      title: '星际穿越',
      originalTitle: 'Interstellar',
      aliases: ['星际启示录', 'Interstellar'],
      posterUrl: '$_base 1761948245703-cbf27a3e7502?$_unsplashParams',
      posterUrls: [
        '$_base 1761948245703-cbf27a3e7502?$_unsplashParams',
        '$_base 1419242902325-76d6614b3c28?$_unsplashParams',
        '$_base 1446776811648-aa78eefe8ed8?$_unsplashParams',
        '$_base 1462331940025-496dfbfc7564?$_unsplashParams',
      ],
      rating: 9.3,
      ratingSource: '豆瓣',
      releaseDate: '2014-11-07(中国大陆)',
      episodes: null,
      genres: ['科幻', '剧情', '冒险'],
      region: '美国 英国',
      languages: ['英语'],
      directors: ['克里斯托弗·诺兰'],
      actors: ['马修·麦康纳', '安妮·海瑟薇', '杰西卡·查斯坦', '迈克尔·凯恩', '马特·达蒙', '蒂莫西·柴勒梅德'],
      synopsis:
          '在不远的未来，随着地球自然环境的恶化，人类面临着无法生存的威胁。这时科学家们在太阳系中的土星附近发现了一个虫洞，通过它可以打破人类的能力限制，到更遥远外太空寻找延续生命希望的机会。\n\n一个探险小组通过这个虫洞穿越到太阳系之外，他们的目标是找到一颗适合人类移民的星球。在这艘名叫"Endurance"的飞船上，探险队员着面临着前所未有的挑战，在遥远的星系中他们感受到了人性的伟大与渺小。\n\n影片探讨了爱、时间、空间等深刻主题，展现了人类在绝境中的勇气与智慧。诺兰用震撼的视觉效果和严谨的科学理论，为观众呈现了一场关于人类命运的史诗级冒险。',
      viewingParties: [
        ViewingParty(
          id: 1,
          title: '《星际穿越》IMAX重映观影团',
          date: '2026-03-15 19:30',
          location: '北京国际影城IMAX厅',
          participants: 58,
          maxParticipants: 80,
        ),
        ViewingParty(
          id: 2,
          title: '科幻电影爱好者专场',
          date: '2026-03-18 20:00',
          location: '上海大光明电影院',
          participants: 42,
          maxParticipants: 60,
        ),
        ViewingParty(
          id: 3,
          title: '诺兰作品回顾展',
          date: '2026-03-22 14:00',
          location: '深圳万象影城',
          participants: 35,
          maxParticipants: 50,
        ),
      ],
      externalReviews: ExternalReviews(
        doubanUrl: 'https://movie.douban.com/subject/1889243/',
        zhihuUrl: 'https://www.zhihu.com/topic/19579097',
        imdbUrl: 'https://www.imdb.com/title/tt0816692/',
        rottenTomatoesUrl: 'https://www.rottentomatoes.com/m/interstellar_2014',
        tmdbUrl: 'https://www.themoviedb.org/movie/157336',
      ),
    ),
    2: MovieDetail(
      id: 2,
      title: '疾速追杀4',
      originalTitle: 'John Wick: Chapter 4',
      aliases: ['捍卫任务4', 'John Wick: Chapter 4'],
      posterUrl: '$_base 1765510296004-614b6cc204da?$_unsplashParams',
      posterUrls: [
        '$_base 1765510296004-614b6cc204da?$_unsplashParams',
        '$_base 1485846234702-74daa017c485?$_unsplashParams',
        '$_base 1536440136628-849c177e76a1?$_unsplashParams',
      ],
      rating: 8.7,
      ratingSource: '豆瓣',
      releaseDate: '2023-03-24(美国)',
      episodes: null,
      genres: ['动作', '惊悚', '犯罪'],
      region: '美国',
      languages: ['英语', '日语', '俄语', '法语'],
      directors: ['查德·斯塔赫斯基'],
      actors: ['基努·里维斯', '甄子丹', '比尔·斯卡斯加德', '劳伦斯·菲什伯恩', '真田广之', '沙米尔·安德森'],
      synopsis:
          '约翰·威克发现了击败高桌会议的可能之路。但在他获得自由之前，威克必须面对一个拥有强大联盟的新敌人，这个敌人将昔日的朋友变成了敌人，并且让全世界最强大的杀手们都来追杀他。\n\n在这部系列的第四章中，约翰·威克的复仇之路达到了新的高度。从纽约到巴黎，从柏林到大阪，威克在世界各地展开了一场场惊心动魄的战斗。影片的动作场面设计达到了系列的巅峰，尤其是在巴黎凯旋门的追车戏和日本大阪的武士刀对决，都成为了动作电影史上的经典片段。\n\n基努·里维斯再次完美诠释了这个传奇杀手的形象，而甄子丹的加盟更是为影片增添了东方武术的魅力。',
      viewingParties: [
        ViewingParty(
          id: 4,
          title: '《疾速追杀4》动作片之夜',
          date: '2026-03-20 21:00',
          location: '北京耀莱成龙影城',
          participants: 67,
          maxParticipants: 100,
        ),
        ViewingParty(
          id: 5,
          title: '基努·里维斯作品回顾',
          date: '2026-03-25 19:00',
          location: '上海影城',
          participants: 48,
          maxParticipants: 70,
        ),
        ViewingParty(
          id: 6,
          title: '动作电影爱好者聚会',
          date: '2026-03-28 20:30',
          location: '广州飞扬影城',
          participants: 52,
          maxParticipants: 80,
        ),
      ],
      externalReviews: ExternalReviews(
        doubanUrl: 'https://movie.douban.com/subject/26588308/',
        zhihuUrl: 'https://www.zhihu.com/topic/20196318',
        imdbUrl: 'https://www.imdb.com/title/tt10366206/',
        rottenTomatoesUrl: 'https://www.rottentomatoes.com/m/john_wick_chapter_4',
        tmdbUrl: 'https://www.themoviedb.org/movie/603692',
      ),
    ),
    3: MovieDetail(
      id: 3,
      title: '彩色梦境',
      originalTitle: 'Colorful Dreams',
      aliases: ['梦幻色彩', 'Colorful Dreams'],
      posterUrl: '$_base 1769311698182-753ea8d1eda0?$_unsplashParams',
      posterUrls: [
        '$_base 1769311698182-753ea8d1eda0?$_unsplashParams',
        '$_base 1518837695005-2083093ee35b?$_unsplashParams',
        '$_base 1579546929518-9e396f3cc809?$_unsplashParams',
        '$_base 1557672172-298b65fb3e17?$_unsplashParams',
        '$_base 1541701494587-cb58502866ab?$_unsplashParams',
      ],
      rating: 8.8,
      ratingSource: '豆瓣',
      releaseDate: '2024-07-12(中国大陆)',
      episodes: null,
      genres: ['动画', '奇幻', '冒险'],
      region: '中国大陆 日本',
      languages: ['汉语普通话', '日语'],
      directors: ['宫崎骏', '新海诚'],
      actors: ['花泽香菜', '神木隆之介', '上白石萌音', '长泽雅美'],
      synopsis:
          '《彩色梦境》是一部充满想象力的动画电影，讲述了一个关于梦想、勇气和友谊的温暖故事。故事的主人公是一个拥有特殊能力的少女，她可以进入他人的梦境，帮助人们找回失去的记忆和勇气。\n\n在一次意外中，她进入了一个神秘的彩色世界，在那里遇到了各种奇妙的生物和挑战。为了回到现实世界，她必须完成一系列的任务，在这个过程中，她不仅帮助了梦境中的居民，也找到了自己内心真正的力量。\n\n影片以绚丽的色彩和流畅的动画技术，创造了一个如梦似幻的视觉世界。每一帧画面都充满了艺术感，配合优美的音乐，为观众带来了一场视听盛宴。',
      viewingParties: [
        ViewingParty(
          id: 7,
          title: '《彩色梦境》动画电影专场',
          date: '2026-04-05 15:00',
          location: '北京UME国际影城',
          participants: 38,
          maxParticipants: 60,
        ),
        ViewingParty(
          id: 8,
          title: '亲子观影活动',
          date: '2026-04-08 10:30',
          location: '上海和平影都',
          participants: 55,
          maxParticipants: 80,
        ),
        ViewingParty(
          id: 9,
          title: '动画爱好者交流会',
          date: '2026-04-12 19:00',
          location: '深圳嘉禾影城',
          participants: 42,
          maxParticipants: 60,
        ),
      ],
      externalReviews: ExternalReviews(
        doubanUrl: 'https://movie.douban.com',
        zhihuUrl: 'https://www.zhihu.com',
        imdbUrl: 'https://www.imdb.com',
        rottenTomatoesUrl: 'https://www.rottentomatoes.com',
        tmdbUrl: 'https://www.themoviedb.org',
      ),
    ),
  };

  /// 根据电影 ID 获取电影详情（模拟 API 调用）
  /// 后续替换为真实的 API 请求
  static MovieDetail? getMovieDetailById(int movieId) {
    return _movieDetailsById[movieId];
  }
}

import { useState } from "react";
import { Search, Rss, TrendingUp, Calendar, Heart } from "lucide-react";
import { FeedCard } from "./components/FeedCard";
import { MovieCarousel } from "./components/MovieCarousel";
import { EventCard } from "./components/EventCard";
import { RankingList } from "./components/RankingList";
import { MovieCard } from "./components/MovieCard";

// 动态数据
const feedData = [
  {
    id: 1,
    userName: "电影爱好者小王",
    userAvatar: "https://images.unsplash.com/photo-1763536529823-953ff472bf35?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhc2lhbiUyMG1hbiUyMHByb2ZpbGUlMjBwb3J0cmFpdHxlbnwxfHx8fDE3NzE3NjY1MjB8MA&ixlib=rb-4.1.0&q=80&w=1080",
    timeAgo: "2小时前",
    content: "刚看完这部科幻大片，视觉效果太震撼了！强烈推荐给喜欢科幻的朋友们 🎬✨",
    movieTitle: "星际穿越",
    moviePoster: "https://images.unsplash.com/photo-1761948245703-cbf27a3e7502?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzY2ktZmklMjBtb3ZpZSUyMHBvc3RlcnxlbnwxfHx8fDE3NzE3MDczMzl8MA&ixlib=rb-4.1.0&q=80&w=1080",
    rating: 9.3,
    likes: 234,
    comments: 45,
    shares: 23,
  },
  {
    id: 2,
    userName: "影评人李华",
    userAvatar: "https://images.unsplash.com/photo-1569913486515-b74bf7751574?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhc2lhbiUyMHdvbWFuJTIwcHJvZmlsZSUyMHBvcnRyYWl0fGVufDF8fHx8MTc3MTc1MDk1OXww&ixlib=rb-4.1.0&q=80&w=1080",
    timeAgo: "5小时前",
    content: "今天参加了首映礼，这部动作片节奏紧凑，打斗场面设计得非常精彩！导演真的太厉害了 👏",
    movieTitle: "疾速追杀4",
    moviePoster: "https://images.unsplash.com/photo-1765510296004-614b6cc204da?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhY3Rpb24lMjBtb3ZpZSUyMHBvc3RlcnxlbnwxfHx8fDE3NzE2NzUwNDd8MA&ixlib=rb-4.1.0&q=80&w=1080",
    rating: 8.7,
    likes: 567,
    comments: 89,
    shares: 34,
  },
  {
    id: 3,
    userName: "张明",
    userAvatar: "https://images.unsplash.com/photo-1563481911853-c14860cd6947?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx5b3VuZyUyMGNoaW5lc2UlMjBtYW4lMjBwb3J0cmFpdHxlbnwxfHx8fDE3NzE3NjY1MjF8MA&ixlib=rb-4.1.0&q=80&w=1080",
    timeAgo: "1天前",
    content: "周末和朋友一起去看了这部奇幻电影，特效制作真的太用心了，每一帧都是壁纸级别！",
    movieTitle: "奇幻星球",
    moviePoster: "https://images.unsplash.com/photo-1763244734635-72b34a167bd5?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmYW50YXN5JTIwY2luZW1hJTIwcG9zdGVyfGVufDF8fHx8MTc3MTc2NjAwOHww&ixlib=rb-4.1.0&q=80&w=1080",
    rating: 7.9,
    likes: 189,
    comments: 32,
    shares: 15,
  },
];

// 轮播图电影数据
const carouselMovies = [
  {
    id: 1,
    title: "星际穿越",
    imageUrl: "https://images.unsplash.com/photo-1761948245703-cbf27a3e7502?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzY2ktZmklMjBtb3ZpZSUyMHBvc3RlcnxlbnwxfHx8fDE3NzE3MDczMzl8MA&ixlib=rb-4.1.0&q=80&w=1080",
    rating: 9.3,
    description: "一场超越时空的冒险，探索宇宙的奥秘与人类的未来。",
  },
  {
    id: 2,
    title: "疾速追杀4",
    imageUrl: "https://images.unsplash.com/photo-1765510296004-614b6cc204da?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhY3Rpb24lMjBtb3ZpZSUyMHBvc3RlcnxlbnwxfHx8fDE3NzE2NzUwNDd8MA&ixlib=rb-4.1.0&q=80&w=1080",
    rating: 8.7,
    description: "最精彩的动作巨制，惊险刺激的追逐与战斗场面。",
  },
  {
    id: 3,
    title: "奇幻星球",
    imageUrl: "https://images.unsplash.com/photo-1763244734635-72b34a167bd5?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmYW50YXN5JTIwY2luZW1hJTIwcG9zdGVyfGVufDF8fHx8MTc3MTc2NjAwOHww&ixlib=rb-4.1.0&q=80&w=1080",
    rating: 7.9,
    description: "充满想象力的奇幻世界，带你进入梦幻般的冒险旅程。",
  },
];

// 排行榜数据
const weeklyRanking = [
  {
    id: 1,
    rank: 1,
    title: "星际穿越",
    imageUrl: "https://images.unsplash.com/photo-1761948245703-cbf27a3e7502?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzY2ktZmklMjBtb3ZpZSUyMHBvc3RlcnxlbnwxfHx8fDE3NzE3MDczMzl8MA&ixlib=rb-4.1.0&q=80&w=1080",
    rating: 9.3,
    change: 2,
    genre: "科幻",
  },
  {
    id: 2,
    rank: 2,
    title: "疾速追杀4",
    imageUrl: "https://images.unsplash.com/photo-1765510296004-614b6cc204da?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhY3Rpb24lMjBtb3ZpZSUyMHBvc3RlcnxlbnwxfHx8fDE3NzE2NzUwNDd8MA&ixlib=rb-4.1.0&q=80&w=1080",
    rating: 8.7,
    change: -1,
    genre: "动作",
  },
  {
    id: 3,
    rank: 3,
    title: "彩色梦境",
    imageUrl: "https://images.unsplash.com/photo-1769311698182-753ea8d1eda0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhbmltYXRlZCUyMG1vdmllJTIwY29sb3JmdWx8ZW58MXx8fHwxNzcxNjgwNjQzfDA&ixlib=rb-4.1.0&q=80&w=1080",
    rating: 8.8,
    change: 1,
    genre: "动画",
  },
  {
    id: 4,
    rank: 4,
    title: "深夜惊魂",
    imageUrl: "https://images.unsplash.com/photo-1653853301139-f57c5fdc069a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxob3Jyb3IlMjBtb3ZpZSUyMGRhcmslMjBjaW5lbWF8ZW58MXx8fHwxNzcxNzY2MDExfDA&ixlib=rb-4.1.0&q=80&w=1080",
    rating: 8.2,
    change: 0,
    genre: "恐怖",
  },
  {
    id: 5,
    rank: 5,
    title: "奇幻星球",
    imageUrl: "https://images.unsplash.com/photo-1763244734635-72b34a167bd5?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmYW50YXN5JTIwY2luZW1hJTIwcG9zdGVyfGVufDF8fHx8MTc3MTc2NjAwOHww&ixlib=rb-4.1.0&q=80&w=1080",
    rating: 7.9,
    change: -2,
    genre: "奇幻",
  },
];

// 活动数据
const eventsData = [
  {
    id: 1,
    title: "第76届戛纳国际电影节展映",
    imageUrl: "https://images.unsplash.com/photo-1741569409778-e7a23b87cfd7?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmaWxtJTIwZmVzdGl2YWwlMjBldmVudCUyMGJhbm5lcnxlbnwxfHx8fDE3NzE3NjY1MjJ8MA&ixlib=rb-4.1.0&q=80&w=1080",
    date: "2026年3月15日",
    location: "北京国际影城",
    participants: 1250,
    type: "电影节",
  },
  {
    id: 2,
    title: "经典科幻电影回顾展",
    imageUrl: "https://images.unsplash.com/photo-1761948245703-cbf27a3e7502?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzY2ktZmklMjBtb3ZpZSUyMHBvc3RlcnxlbnwxfHx8fDE3NzE3MDczMzl8MA&ixlib=rb-4.1.0&q=80&w=1080",
    date: "2026年3月20日",
    location: "上海大光明电影院",
    participants: 680,
    type: "主题展映",
  },
  {
    id: 3,
    title: "导演见面会：探索电影艺术",
    imageUrl: "https://images.unsplash.com/photo-1765510296004-614b6cc204da?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhY3Rpb24lMjBtb3ZpZSUyMHBvc3RlcnxlbnwxfHx8fDE3NzE2NzUwNDd8MA&ixlib=rb-4.1.0&q=80&w=1080",
    date: "2026年3月25日",
    location: "深圳影城",
    participants: 320,
    type: "见面会",
  },
  {
    id: 4,
    title: "动画电影嘉年华",
    imageUrl: "https://images.unsplash.com/photo-1769311698182-753ea8d1eda0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhbmltYXRlZCUyMG1vdmllJTIwY29sb3JmdWx8ZW58MXx8fHwxNzcxNjgwNjQzfDA&ixlib=rb-4.1.0&q=80&w=1080",
    date: "2026年4月1日",
    location: "广州太古汇影城",
    participants: 890,
    type: "嘉年华",
  },
];

// 我的收藏
const favoriteMovies = [
  {
    id: 1,
    title: "星际穿越",
    imageUrl: "https://images.unsplash.com/photo-1761948245703-cbf27a3e7502?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzY2ktZmklMjBtb3ZpZSUyMHBvc3RlcnxlbnwxfHx8fDE3NzE3MDczMzl8MA&ixlib=rb-4.1.0&q=80&w=1080",
    rating: 9.3,
    year: "2014",
    genre: "科幻",
  },
  {
    id: 2,
    title: "疾速追杀4",
    imageUrl: "https://images.unsplash.com/photo-1765510296004-614b6cc204da?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhY3Rpb24lMjBtb3ZpZSUyMHBvc3RlcnxlbnwxfHx8fDE3NzE2NzUwNDd8MA&ixlib=rb-4.1.0&q=80&w=1080",
    rating: 8.7,
    year: "2023",
    genre: "动作",
  },
  {
    id: 3,
    title: "彩色梦境",
    imageUrl: "https://images.unsplash.com/photo-1769311698182-753ea8d1eda0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhbmltYXRlZCUyMG1vdmllJTIwY29sb3JmdWx8ZW58MXx8fHwxNzcxNjgwNjQzfDA&ixlib=rb-4.1.0&q=80&w=1080",
    rating: 8.8,
    year: "2024",
    genre: "动画",
  },
];

type TabType = 'feed' | 'ranking' | 'events' | 'favorites';

export default function App() {
  const [activeTab, setActiveTab] = useState<TabType>('feed');
  const [searchQuery, setSearchQuery] = useState("");

  const tabs = [
    { id: 'feed' as TabType, label: '动态', icon: Rss },
    { id: 'ranking' as TabType, label: '热门榜单', icon: TrendingUp },
    { id: 'events' as TabType, label: '热门活动', icon: Calendar },
    { id: 'favorites' as TabType, label: '我的收藏', icon: Heart },
  ];

  const renderContent = () => {
    switch (activeTab) {
      case 'feed':
        return (
          <div>
            {feedData.map((feed) => (
              <FeedCard key={feed.id} {...feed} />
            ))}
          </div>
        );
      
      case 'ranking':
        return (
          <div>
            <MovieCarousel movies={carouselMovies} />
            <RankingList movies={weeklyRanking} title="本周热门电影" />
            <div className="mt-6">
              <h2 className="text-[#015697] mb-4">最新上映</h2>
              <div className="flex gap-4 overflow-x-auto pb-2 scrollbar-hide">
                {favoriteMovies.map((movie) => (
                  <MovieCard key={movie.id} {...movie} />
                ))}
              </div>
            </div>
          </div>
        );
      
      case 'events':
        return (
          <div>
            {eventsData.map((event) => (
              <EventCard key={event.id} {...event} />
            ))}
          </div>
        );
      
      case 'favorites':
        return (
          <div>
            {favoriteMovies.length > 0 ? (
              <>
                <h2 className="text-[#015697] mb-4">我的收藏 ({favoriteMovies.length})</h2>
                <div className="grid grid-cols-3 gap-3">
                  {favoriteMovies.map((movie) => (
                    <MovieCard key={movie.id} {...movie} />
                  ))}
                </div>
              </>
            ) : (
              <div className="text-center py-12">
                <Heart className="w-16 h-16 text-[#A0C3D9] mx-auto mb-4" />
                <h2 className="text-[#015697] mb-2">暂无收藏</h2>
                <p className="text-[#5F7689]">快去添加你喜欢的电影吧！</p>
              </div>
            )}
          </div>
        );
    }
  };

  return (
    <div className="min-h-screen bg-[#feffef] pb-24">
      {/* 头部搜索栏 */}
      <div className="sticky top-0 bg-[#015697] px-4 pt-12 pb-4 shadow-md z-10">
        <div className="relative">
          <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-[#5F7689] w-5 h-5" />
          <input
            type="text"
            placeholder="搜索电影、演员、导演..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-12 pr-4 py-3 bg-white rounded-full text-[#015697] placeholder-[#5F7689] focus:outline-none focus:ring-2 focus:ring-[#FEBF9C]"
          />
        </div>
      </div>

      {/* Tab导航 */}
      <div className="sticky top-[120px] bg-[#feffef] border-b border-[#A0C3D9]/30 px-4 z-10">
        <div className="flex gap-2 overflow-x-auto scrollbar-hide">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-2 px-4 py-3 whitespace-nowrap transition-colors relative ${
                  isActive
                    ? 'text-[#015697]'
                    : 'text-[#5F7689] hover:text-[#015697]'
                }`}
              >
                <Icon className="w-4 h-4" />
                <span>{tab.label}</span>
                {isActive && (
                  <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-[#FEBF9C]" />
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* 内容区域 */}
      <div className="px-4 pt-6">
        {renderContent()}
      </div>
    </div>
  );
}

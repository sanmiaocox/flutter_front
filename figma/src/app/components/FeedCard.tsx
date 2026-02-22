import { useState } from "react";
import { Heart, MessageCircle, Share2, MoreHorizontal } from "lucide-react";

interface FeedCardProps {
  id: number;
  userName: string;
  userAvatar: string;
  timeAgo: string;
  content: string;
  movieTitle?: string;
  moviePoster?: string;
  rating?: number;
  likes: number;
  comments: number;
  shares: number;
}

export function FeedCard({
  userName,
  userAvatar,
  timeAgo,
  content,
  movieTitle,
  moviePoster,
  rating,
  likes: initialLikes,
  comments,
  shares,
}: FeedCardProps) {
  const [liked, setLiked] = useState(false);
  const [likes, setLikes] = useState(initialLikes);

  const handleLike = () => {
    if (liked) {
      setLikes(likes - 1);
    } else {
      setLikes(likes + 1);
    }
    setLiked(!liked);
  };

  return (
    <div className="bg-white rounded-2xl p-4 mb-4 shadow-sm">
      {/* 用户信息 */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-3">
          <img
            src={userAvatar}
            alt={userName}
            className="w-10 h-10 rounded-full object-cover"
          />
          <div>
            <h3 className="text-[#015697] font-medium">{userName}</h3>
            <p className="text-xs text-[#5F7689]">{timeAgo}</p>
          </div>
        </div>
        <button className="text-[#5F7689] hover:text-[#015697]">
          <MoreHorizontal className="w-5 h-5" />
        </button>
      </div>

      {/* 动态内容 */}
      <p className="text-[#015697] mb-3">{content}</p>

      {/* 电影卡片 */}
      {movieTitle && moviePoster && (
        <div className="bg-[#feffef] rounded-xl p-3 mb-3 flex gap-3">
          <img
            src={moviePoster}
            alt={movieTitle}
            className="w-20 h-28 object-cover rounded-lg"
          />
          <div className="flex-1">
            <h4 className="text-[#015697] font-medium mb-1">{movieTitle}</h4>
            {rating && (
              <div className="flex items-center gap-1 text-[#FEBF9C] mb-2">
                <span className="text-sm">⭐</span>
                <span className="text-sm font-medium">{rating}</span>
              </div>
            )}
            <button className="bg-[#015697] text-white px-4 py-1.5 rounded-full text-sm hover:bg-[#015697]/90 transition-colors">
              查看详情
            </button>
          </div>
        </div>
      )}

      {/* 互动按钮 */}
      <div className="flex items-center justify-between pt-3 border-t border-[#A0C3D9]/30">
        <button
          onClick={handleLike}
          className={`flex items-center gap-2 transition-colors ${
            liked ? "text-[#FEBF9C]" : "text-[#5F7689] hover:text-[#FEBF9C]"
          }`}
        >
          <Heart className={`w-5 h-5 ${liked ? "fill-current" : ""}`} />
          <span className="text-sm">{likes}</span>
        </button>
        <button className="flex items-center gap-2 text-[#5F7689] hover:text-[#015697] transition-colors">
          <MessageCircle className="w-5 h-5" />
          <span className="text-sm">{comments}</span>
        </button>
        <button className="flex items-center gap-2 text-[#5F7689] hover:text-[#015697] transition-colors">
          <Share2 className="w-5 h-5" />
          <span className="text-sm">{shares}</span>
        </button>
      </div>
    </div>
  );
}

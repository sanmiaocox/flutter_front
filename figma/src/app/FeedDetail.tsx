import { useState } from "react";
import { useParams, useNavigate } from "react-router";
import { ArrowLeft, Heart, MessageCircle, Share2, MoreHorizontal, Send } from "lucide-react";
import { feedData } from "./HomePage";
import { CommentList } from "./components/CommentList";

// 模拟评论数据
const commentsData: Record<number, any[]> = {
  1: [
    {
      id: 1,
      userName: "影迷小李",
      userAvatar: "https://images.unsplash.com/photo-1569913486515-b74bf7751574?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhc2lhbiUyMHdvbWFuJTIwcHJvZmlsZSUyMHBvcnRyYWl0fGVufDF8fHx8MTc3MTc1MDk1OXww&ixlib=rb-4.1.0&q=80&w=1080",
      content: "我也超级喜欢这部电影！特效真的太棒了，尤其是黑洞那段😍",
      timeAgo: "1小时前",
      likes: 23,
    },
    {
      id: 2,
      userName: "电影发烧友",
      userAvatar: "https://images.unsplash.com/photo-1563481911853-c14860cd6947?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx5b3VuZyUyMGNoaW5lc2UlMjBtYW4lMjBwb3J0cmFpdHxlbnwxfHx8fDE3NzE3NjY1MjF8MA&ixlib=rb-4.1.0&q=80&w=1080",
      content: "诺兰的作品从来不会让人失望，这部更是巅峰之作！",
      timeAgo: "2小时前",
      likes: 45,
    },
    {
      id: 3,
      userName: "科幻爱好者",
      userAvatar: "https://images.unsplash.com/photo-1763536529823-953ff472bf35?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhc2lhbiUyMG1hbiUyMHByb2ZpbGUlMjBwb3J0cmFpdHxlbnwxfHx8fDE3NzE3NjY1MjB8MA&ixlib=rb-4.1.0&q=80&w=1080",
      content: "时间膨胀的设定太精彩了，看完之后还在思考里面的科学原理",
      timeAgo: "3小时前",
      likes: 12,
    },
  ],
  2: [
    {
      id: 1,
      userName: "动作片粉丝",
      userAvatar: "https://images.unsplash.com/photo-1569913486515-b74bf7751574?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhc2lhbiUyMHdvbWFuJTIwcHJvZmlsZSUyMHBvcnRyYWl0fGVufDF8fHx8MTc3MTc1MDk1OXww&ixlib=rb-4.1.0&q=80&w=1080",
      content: "基努里维斯的动作戏真的是越来越厉害了！",
      timeAgo: "30分钟前",
      likes: 67,
    },
    {
      id: 2,
      userName: "电影评论家",
      userAvatar: "https://images.unsplash.com/photo-1763536529823-953ff472bf35?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhc2lhbiUyMG1hbiUyMHByb2ZpbGUlMjBwb3J0cmFpdHxlbnwxfHx8fDE3NzE3NjY1MjB8MA&ixlib=rb-4.1.0&q=80&w=1080",
      content: "这一部比前作更加精彩，打斗场面设计得非常用心👍",
      timeAgo: "1小时前",
      likes: 34,
    },
  ],
  3: [
    {
      id: 1,
      userName: "奇幻迷",
      userAvatar: "https://images.unsplash.com/photo-1563481911853-c14860cd6947?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx5b3VuZyUyMGNoaW5lc2UlMjBtYW4lMjBwb3J0cmFpdHxlbnwxfHx8fDE3NzE3NjY1MjF8MA&ixlib=rb-4.1.0&q=80&w=1080",
      content: "画面真的美到窒息，每一帧都想截图当壁纸！",
      timeAgo: "5小时前",
      likes: 28,
    },
  ],
};

export default function FeedDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [commentText, setCommentText] = useState("");
  const [comments, setComments] = useState(commentsData[Number(id)] || []);
  const [liked, setLiked] = useState(false);
  
  const feedId = Number(id);
  const feed = feedData.find((f) => f.id === feedId);

  if (!feed) {
    return (
      <div className="min-h-screen bg-[#feffef] flex items-center justify-center">
        <p className="text-[#5F7689]">动态不存在</p>
      </div>
    );
  }

  const [likes, setLikes] = useState(feed.likes);

  const handleBack = () => {
    navigate(-1);
  };

  const handleLike = () => {
    if (liked) {
      setLikes(likes - 1);
    } else {
      setLikes(likes + 1);
    }
    setLiked(!liked);
  };

  const handleSendComment = () => {
    if (!commentText.trim()) return;

    const newComment = {
      id: comments.length + 1,
      userName: "我",
      userAvatar: "https://images.unsplash.com/photo-1763536529823-953ff472bf35?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhc2lhbiUyMG1hbiUyMHByb2ZpbGUlMjBwb3J0cmFpdHxlbnwxfHx8fDE3NzE3NjY1MjB8MA&ixlib=rb-4.1.0&q=80&w=1080",
      content: commentText,
      timeAgo: "刚刚",
      likes: 0,
    };

    setComments([newComment, ...comments]);
    setCommentText("");
  };

  return (
    <div className="min-h-screen bg-[#feffef] flex flex-col">
      {/* 顶部导航栏 */}
      <div className="sticky top-0 bg-[#015697] px-4 py-4 shadow-md z-10 flex items-center gap-3">
        <button
          onClick={handleBack}
          className="text-white hover:text-[#FEBF9C] transition-colors"
        >
          <ArrowLeft className="w-6 h-6" />
        </button>
        <h1 className="text-white text-lg font-medium">动态详情</h1>
      </div>

      {/* 内容区域 - 可滚动 */}
      <div className="flex-1 overflow-y-auto pb-20">
        {/* 动态内容 */}
        <div className="bg-white p-4 mb-2">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-3">
              <img
                src={feed.userAvatar}
                alt={feed.userName}
                className="w-10 h-10 rounded-full object-cover"
              />
              <div>
                <h3 className="text-[#015697] font-medium">{feed.userName}</h3>
                <p className="text-xs text-[#5F7689]">{feed.timeAgo}</p>
              </div>
            </div>
            <button className="text-[#5F7689] hover:text-[#015697]">
              <MoreHorizontal className="w-5 h-5" />
            </button>
          </div>

          <p className="text-[#015697] mb-3">{feed.content}</p>

          {feed.movieTitle && feed.moviePoster && (
            <div className="bg-[#feffef] rounded-xl p-3 mb-3 flex gap-3">
              <img
                src={feed.moviePoster}
                alt={feed.movieTitle}
                className="w-20 h-28 object-cover rounded-lg"
              />
              <div className="flex-1">
                <h4 className="text-[#015697] font-medium mb-1">{feed.movieTitle}</h4>
                {feed.rating && (
                  <div className="flex items-center gap-1 text-[#FEBF9C] mb-2">
                    <span className="text-sm">⭐</span>
                    <span className="text-sm font-medium">{feed.rating}</span>
                  </div>
                )}
                <button className="bg-[#015697] text-white px-4 py-1.5 rounded-full text-sm hover:bg-[#015697]/90 transition-colors">
                  查看详情
                </button>
              </div>
            </div>
          )}

          {/* 互动统计 */}
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
            <button className="flex items-center gap-2 text-[#5F7689]">
              <MessageCircle className="w-5 h-5" />
              <span className="text-sm">{comments.length}</span>
            </button>
            <button className="flex items-center gap-2 text-[#5F7689] hover:text-[#015697] transition-colors">
              <Share2 className="w-5 h-5" />
              <span className="text-sm">{feed.shares}</span>
            </button>
          </div>
        </div>

        {/* 评论区 */}
        <div className="bg-white p-4">
          <h3 className="text-[#015697] font-medium mb-4">
            全部评论 ({comments.length})
          </h3>
          {comments.length > 0 ? (
            <CommentList comments={comments} />
          ) : (
            <div className="text-center py-12">
              <MessageCircle className="w-12 h-12 text-[#A0C3D9] mx-auto mb-3" />
              <p className="text-[#5F7689]">暂无评论，快来抢沙发吧～</p>
            </div>
          )}
        </div>
      </div>

      {/* 底部评论输入框 - 固定 */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-[#A0C3D9]/30 p-4 shadow-lg">
        <div className="flex items-center gap-3">
          <input
            type="text"
            placeholder="说点什么..."
            value={commentText}
            onChange={(e) => setCommentText(e.target.value)}
            onKeyPress={(e) => {
              if (e.key === 'Enter') {
                handleSendComment();
              }
            }}
            className="flex-1 px-4 py-2.5 bg-[#feffef] rounded-full text-[#015697] placeholder-[#5F7689] focus:outline-none focus:ring-2 focus:ring-[#015697]"
          />
          <button
            onClick={handleSendComment}
            disabled={!commentText.trim()}
            className={`p-2.5 rounded-full transition-colors ${
              commentText.trim()
                ? "bg-[#015697] text-white hover:bg-[#015697]/90"
                : "bg-[#A0C3D9] text-white cursor-not-allowed"
            }`}
          >
            <Send className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}

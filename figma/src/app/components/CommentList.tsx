import { useState } from "react";
import { Heart } from "lucide-react";

interface Comment {
  id: number;
  userName: string;
  userAvatar: string;
  content: string;
  timeAgo: string;
  likes: number;
}

interface CommentListProps {
  comments: Comment[];
}

export function CommentList({ comments }: CommentListProps) {
  return (
    <div className="space-y-4">
      {comments.map((comment) => (
        <CommentItem key={comment.id} {...comment} />
      ))}
    </div>
  );
}

function CommentItem({ userName, userAvatar, content, timeAgo, likes: initialLikes }: Comment) {
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
    <div className="flex gap-3">
      <img
        src={userAvatar}
        alt={userName}
        className="w-10 h-10 rounded-full object-cover flex-shrink-0"
      />
      <div className="flex-1">
        <div className="bg-[#feffef] rounded-xl p-3">
          <h4 className="text-[#015697] font-medium text-sm mb-1">{userName}</h4>
          <p className="text-[#015697] text-sm">{content}</p>
        </div>
        <div className="flex items-center gap-4 mt-2 px-3">
          <span className="text-xs text-[#5F7689]">{timeAgo}</span>
          <button
            onClick={handleLike}
            className={`flex items-center gap-1 text-xs transition-colors ${
              liked ? "text-[#FEBF9C]" : "text-[#5F7689] hover:text-[#FEBF9C]"
            }`}
          >
            <Heart className={`w-3.5 h-3.5 ${liked ? "fill-current" : ""}`} />
            <span>{likes}</span>
          </button>
        </div>
      </div>
    </div>
  );
}

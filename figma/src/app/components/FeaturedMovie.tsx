import { Play, Info } from "lucide-react";

interface FeaturedMovieProps {
  title: string;
  imageUrl: string;
  description: string;
  rating: number;
}

export function FeaturedMovie({ title, imageUrl, description, rating }: FeaturedMovieProps) {
  return (
    <div className="relative h-64 rounded-2xl overflow-hidden shadow-lg mb-6">
      <img 
        src={imageUrl} 
        alt={title}
        className="w-full h-full object-cover"
      />
      <div className="absolute inset-0 bg-gradient-to-t from-[#015697]/90 via-[#015697]/40 to-transparent">
        <div className="absolute bottom-0 left-0 right-0 p-6">
          <h2 className="text-white text-2xl font-bold mb-2">{title}</h2>
          <p className="text-white/90 text-sm mb-4 line-clamp-2">{description}</p>
          <div className="flex gap-3">
            <button className="bg-[#FEBF9C] text-[#015697] px-6 py-2 rounded-full flex items-center gap-2 hover:bg-[#FEBF9C]/90 transition-colors">
              <Play className="w-4 h-4 fill-current" />
              <span>立即播放</span>
            </button>
            <button className="bg-white/20 backdrop-blur-sm text-white px-6 py-2 rounded-full flex items-center gap-2 hover:bg-white/30 transition-colors">
              <Info className="w-4 h-4" />
              <span>详情</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

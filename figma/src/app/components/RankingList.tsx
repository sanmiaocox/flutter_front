import { TrendingUp, TrendingDown, Minus } from "lucide-react";

interface RankingMovie {
  id: number;
  rank: number;
  title: string;
  imageUrl: string;
  rating: number;
  change: number; // 正数上升，负数下降，0持平
  genre: string;
}

interface RankingListProps {
  movies: RankingMovie[];
  title: string;
}

export function RankingList({ movies, title }: RankingListProps) {
  const getRankColor = (rank: number) => {
    if (rank === 1) return "bg-[#FEBF9C] text-[#015697]";
    if (rank === 2) return "bg-[#A0C3D9] text-[#015697]";
    if (rank === 3) return "bg-[#5F7689] text-white";
    return "bg-white text-[#5F7689] border border-[#A0C3D9]/30";
  };

  const getTrendIcon = (change: number) => {
    if (change > 0) return <TrendingUp className="w-4 h-4 text-green-500" />;
    if (change < 0) return <TrendingDown className="w-4 h-4 text-red-500" />;
    return <Minus className="w-4 h-4 text-[#5F7689]" />;
  };

  return (
    <div className="mb-6">
      <h2 className="text-[#015697] mb-4">{title}</h2>
      <div className="space-y-3">
        {movies.map((movie) => (
          <div
            key={movie.id}
            className="bg-white rounded-xl p-3 shadow-sm flex items-center gap-3"
          >
            <div
              className={`w-8 h-8 flex items-center justify-center rounded-lg font-bold text-sm flex-shrink-0 ${getRankColor(
                movie.rank
              )}`}
            >
              {movie.rank}
            </div>
            <img
              src={movie.imageUrl}
              alt={movie.title}
              className="w-12 h-16 object-cover rounded-md flex-shrink-0"
            />
            <div className="flex-1 min-w-0">
              <h3 className="text-[#015697] font-medium text-sm mb-1 truncate">
                {movie.title}
              </h3>
              <div className="flex items-center gap-2">
                <span className="text-xs text-[#5F7689]">{movie.genre}</span>
                <span className="text-xs text-[#FEBF9C] font-medium">
                  ⭐ {movie.rating}
                </span>
              </div>
            </div>
            <div className="flex items-center gap-1 flex-shrink-0">
              {getTrendIcon(movie.change)}
              {movie.change !== 0 && (
                <span className="text-xs text-[#5F7689]">
                  {Math.abs(movie.change)}
                </span>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

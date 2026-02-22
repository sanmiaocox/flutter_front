import { Star } from "lucide-react";

interface MovieCardProps {
  title: string;
  imageUrl: string;
  rating: number;
  year: string;
  genre: string;
}

export function MovieCard({ title, imageUrl, rating, year, genre }: MovieCardProps) {
  return (
    <div className="flex-shrink-0 w-32 cursor-pointer group">
      <div className="relative rounded-lg overflow-hidden shadow-md mb-2 aspect-[2/3]">
        <img 
          src={imageUrl} 
          alt={title}
          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
        />
        <div className="absolute top-2 right-2 bg-[#015697] text-white px-2 py-1 rounded-md flex items-center gap-1 text-xs">
          <Star className="w-3 h-3 fill-[#FEBF9C] text-[#FEBF9C]" />
          <span>{rating}</span>
        </div>
      </div>
      <h3 className="font-medium text-sm text-[#015697] mb-1 line-clamp-2">{title}</h3>
      <p className="text-xs text-[#5F7689]">{year} · {genre}</p>
    </div>
  );
}

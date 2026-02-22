import Slider from "react-slick";
import { Star, Play } from "lucide-react";

interface CarouselMovie {
  id: number;
  title: string;
  imageUrl: string;
  rating: number;
  description: string;
}

interface MovieCarouselProps {
  movies: CarouselMovie[];
}

export function MovieCarousel({ movies }: MovieCarouselProps) {
  const settings = {
    dots: true,
    infinite: true,
    speed: 500,
    slidesToShow: 1,
    slidesToScroll: 1,
    autoplay: true,
    autoplaySpeed: 3000,
    arrows: false,
  };

  return (
    <div className="mb-6">
      <Slider {...settings}>
        {movies.map((movie) => (
          <div key={movie.id}>
            <div className="relative h-56 rounded-2xl overflow-hidden">
              <img
                src={movie.imageUrl}
                alt={movie.title}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#015697]/95 via-[#015697]/50 to-transparent">
                <div className="absolute bottom-0 left-0 right-0 p-5">
                  <div className="flex items-center gap-2 mb-2">
                    <div className="bg-[#FEBF9C] text-[#015697] px-2 py-1 rounded-md flex items-center gap-1 text-sm">
                      <Star className="w-3 h-3 fill-current" />
                      <span>{movie.rating}</span>
                    </div>
                    <span className="text-white/80 text-sm">热门推荐</span>
                  </div>
                  <h3 className="text-white text-xl font-bold mb-2">
                    {movie.title}
                  </h3>
                  <p className="text-white/90 text-sm mb-3 line-clamp-2">
                    {movie.description}
                  </p>
                  <button className="bg-[#FEBF9C] text-[#015697] px-6 py-2 rounded-full flex items-center gap-2 hover:bg-[#FEBF9C]/90 transition-colors">
                    <Play className="w-4 h-4 fill-current" />
                    <span>立即观看</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </Slider>
    </div>
  );
}

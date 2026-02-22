import { Calendar, MapPin, Users } from "lucide-react";

interface EventCardProps {
  id: number;
  title: string;
  imageUrl: string;
  date: string;
  location: string;
  participants: number;
  type: string;
}

export function EventCard({
  title,
  imageUrl,
  date,
  location,
  participants,
  type,
}: EventCardProps) {
  return (
    <div className="bg-white rounded-2xl overflow-hidden shadow-sm mb-4">
      <div className="relative h-40">
        <img
          src={imageUrl}
          alt={title}
          className="w-full h-full object-cover"
        />
        <div className="absolute top-3 right-3 bg-[#FEBF9C] text-[#015697] px-3 py-1 rounded-full text-xs font-medium">
          {type}
        </div>
      </div>
      <div className="p-4">
        <h3 className="text-[#015697] font-medium mb-3">{title}</h3>
        <div className="space-y-2 mb-4">
          <div className="flex items-center gap-2 text-[#5F7689] text-sm">
            <Calendar className="w-4 h-4" />
            <span>{date}</span>
          </div>
          <div className="flex items-center gap-2 text-[#5F7689] text-sm">
            <MapPin className="w-4 h-4" />
            <span>{location}</span>
          </div>
          <div className="flex items-center gap-2 text-[#5F7689] text-sm">
            <Users className="w-4 h-4" />
            <span>{participants} 人参与</span>
          </div>
        </div>
        <button className="w-full bg-[#015697] text-white py-2.5 rounded-full hover:bg-[#015697]/90 transition-colors">
          报名参加
        </button>
      </div>
    </div>
  );
}

#!/usr/bin/env ruby -wKU

DIST = {cm_to_m: 100, cm_to_km: 100000, m_to_km: 1000}
ROUNDOFF = 2

def range_1000(series)
  series.to_a[0..999]
end 

def format_time(time_in_sec)
  return '' if time_in_sec.nil?
  Time.at(time_in_sec.round).local.strftime("%-H hr, %-M min, %-S sec")
end

def format_dist(dist_in_cm)
  dist_in_cm = dist_in_cm.round(ROUNDOFF)
  if dist_in_cm >= DIST[:cm_to_km]
    "#{(dist_in_cm/DIST[:cm_to_km]).round(ROUNDOFF)} km"
  elsif dist_in_cm >= DIST[:cm_to_m]
    distance = (dist_in_cm/DIST[:cm_to_km]).round(ROUNDOFF)
    (distance == DIST[:m_to_km]) ? "1.0 km" : "#{distance} m"
  else
    dist_in_cm == DIST[:cm_to_m] ? "1.0 m" : "#{dist_in_cm} cm"
  end

end

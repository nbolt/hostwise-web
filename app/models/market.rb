class Market < ActiveRecord::Base
  has_many :zip_codes

  reverse_geocoded_by :lat, :lng
end

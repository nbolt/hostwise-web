class Market < ActiveRecord::Base
  has_many :zip_codes
  has_many :contractor_profiles

  reverse_geocoded_by :lat, :lng
end

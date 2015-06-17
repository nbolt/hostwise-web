class Market < ActiveRecord::Base
  has_many :zip_codes
  has_many :contractor_profiles
  has_many :distribution_centers
  has_many :users

  reverse_geocoded_by :lat, :lng
end

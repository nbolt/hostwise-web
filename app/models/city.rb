class City < ActiveRecord::Base
  include PgSearch
  pg_search_scope :search, against: :name, using: { tsearch: { prefix: true } }

  belongs_to :county, inverse_of: :cities
  has_many :zips, inverse_of: :city

  validates :county, presence: true
  validates :name,   presence: true, uniqueness: {case_sensitive: false, scope: :county_id}

  def state
    county.state
  end
end
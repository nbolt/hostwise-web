class ZipCode < ActiveRecord::Base
  self.table_name = 'zips'

  before_create :assign_market

  belongs_to :market
  belongs_to :neighborhood
  belongs_to :city, inverse_of: :zip_codes
  has_many :properties

  validates :city, presence: true
  validates :code, presence: true, uniqueness: {case_sensitive: false}

  scope :serviced, -> { where(serviced: true) }

  def assign_market
    self.market = Market.near(code)[0]
  end
end
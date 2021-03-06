class ZipCode < ActiveRecord::Base
  self.table_name = 'zips'

  before_save :assign_market

  belongs_to :market
  belongs_to :neighborhood
  belongs_to :city, inverse_of: :zip_codes
  has_many :properties, foreign_key: :zip_id

  # validates :city, presence: true
  # validates :code, presence: true, uniqueness: {case_sensitive: false}

  scope :serviced, -> { where(serviced: true) }

  private

  def assign_market
    self.market = Market.near(code, 50)[0] if serviced
  end
end
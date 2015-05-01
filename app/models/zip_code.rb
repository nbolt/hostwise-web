class ZipCode < ActiveRecord::Base
  self.table_name = 'zips'

  belongs_to :neighborhood
  belongs_to :city, inverse_of: :zip_codes

  validates :city, presence: true
  validates :code, presence: true, uniqueness: {case_sensitive: false}

  scope :serviced, -> { where(serviced: true) }
end
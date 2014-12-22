class Payment < ActiveRecord::Base
  belongs_to :user
  has_many :bookings

  validates :fingerprint, uniqueness: true
end

class Payment < ActiveRecord::Base
  belongs_to :user
  belongs_to :property

  validates :fingerprint, uniqueness: true
end

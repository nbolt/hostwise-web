class Payment < ActiveRecord::Base
  belongs_to :user

  validates :fingerprint, uniqueness: true
end

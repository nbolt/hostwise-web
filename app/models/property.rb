class Property < ActiveRecord::Base
  belongs_to :user
  has_many :bookings, autosave: true, dependent: :destroy
end

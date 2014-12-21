class BookingServices < ActiveRecord::Base
  belongs_to :booking
  belongs_to :service
end

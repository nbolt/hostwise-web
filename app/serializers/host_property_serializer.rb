class HostPropertySerializer < ActiveModel::Serializer
  attributes :id, :nickname, :linen_handling_cd, :neighborhood_address, :next_service_date

  has_many :bookings, serializer: HostBookingSerializer
end

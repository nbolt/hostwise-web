class HostPropertySerializer < ActiveModel::Serializer
  attributes :id, :nickname, :neighborhood_address, :next_service_date

  has_many :bookings, serializer: HostBookingSerializer
end

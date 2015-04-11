class UserPropertySerializer < ActiveModel::Serializer
  attributes :id, :nickname, :neighborhood_address, :property_size, :next_service_date, :display_phone_number, :king_bed_count, :twin_beds, :bathrooms

  has_many :bookings, serializer: PropertyBookingSerializer
end

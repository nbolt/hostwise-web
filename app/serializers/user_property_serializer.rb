class UserPropertySerializer < ActiveModel::Serializer
  attributes :id, :nickname, :slug, :linen_handling_cd, :property_size, :property_type, :display_phone_number, :city, :primary_photo, :short_address, :full_address, :next_service_date

  has_many :property_photos
  has_many :active_bookings, serializer: PropertyBookingSerializer
end

class BookingSerializer < ActiveModel::Serializer
  attributes :id, :property_id, :cost

  has_one :property
end

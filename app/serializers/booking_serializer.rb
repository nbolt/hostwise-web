class BookingSerializer < ActiveModel::Serializer
  attributes :id, :cost

  has_one :property
end

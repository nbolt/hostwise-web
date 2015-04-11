class PropertyBookingSerializer < ActiveModel::Serializer
  attributes :id, :property_id, :cost

  has_many :services
end

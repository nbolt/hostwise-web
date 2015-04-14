class BookingSerializer < ActiveModel::Serializer
  attributes :id, :property_id, :cost, :late_same_day

  has_one :property
  has_one :user
end

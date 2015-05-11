class DataBookingSerializer < ActiveModel::Serializer
  attributes :id, :cost

  has_one :property, serializer: DataPropertySerializer
end

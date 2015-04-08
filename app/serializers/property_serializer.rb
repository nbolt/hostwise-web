class PropertySerializer < ActiveModel::Serializer
  attributes :id, :nickname, :neighborhood_address, :property_size, :next_service_date

  has_one :user
end

class PropertySerializer < ActiveModel::Serializer
  attributes :id, :nickname, :neighborhood_address, :property_size

  has_one :user
end

class PropertySerializer < ActiveModel::Serializer
  attributes :id, :nickname, :neighborhood_address, :property_size, :next_service_date, :display_phone_number

  has_one :user
end

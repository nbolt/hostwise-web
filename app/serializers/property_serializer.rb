class PropertySerializer < ActiveModel::Serializer
  attributes :id, :nickname, :neighborhood_address, :property_size, :display_phone_number, :king_bed_count, :twin_beds, :bathrooms
end

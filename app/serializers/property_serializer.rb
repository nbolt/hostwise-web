class PropertySerializer < ActiveModel::Serializer
  attributes :id, :nickname, :linen_handling_cd, :neighborhood_address, :property_size, :display_phone_number, :king_bed_count, :twin_beds, :bathrooms, :city

  has_one :zip_code
end

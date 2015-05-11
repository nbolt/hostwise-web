class DataPropertySerializer < ActiveModel::Serializer
  attributes :id, :property_type_cd, :property_size, :nickname, :short_address, :full_address, :neighborhood, :primary_photo

  has_one :user, serializer: DataUserSerializer
end

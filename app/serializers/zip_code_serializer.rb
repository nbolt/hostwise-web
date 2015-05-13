class ZipCodeSerializer < ActiveModel::Serializer
  attributes :id, :code

  has_one :market
end

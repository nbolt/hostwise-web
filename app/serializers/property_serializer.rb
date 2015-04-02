class PropertySerializer < ActiveModel::Serializer
  attributes :id, :nickname, :short_address

  has_one :user
end

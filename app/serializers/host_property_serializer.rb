class HostPropertySerializer < ActiveModel::Serializer
  attributes :id, :nickname, :neighborhood_address

  has_many :bookings
end

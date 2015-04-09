class JobSerializer < ActiveModel::Serializer
  attributes :id, :status_cd, :date

  has_many :contractors
  has_many :payouts
  has_one :booking
end

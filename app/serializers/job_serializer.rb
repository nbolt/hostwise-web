class JobSerializer < ActiveModel::Serializer
  attributes :id, :status_cd, :state_cd, :date, :staging, :distribution

  has_many :contractors
  has_many :payouts
  has_one :booking
end

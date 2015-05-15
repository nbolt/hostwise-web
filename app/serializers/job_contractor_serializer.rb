class JobContractorSerializer < ActiveModel::Serializer
  attributes :id, :name

  has_many :payouts
end

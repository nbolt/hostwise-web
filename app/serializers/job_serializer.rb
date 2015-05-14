class JobSerializer < ActiveModel::Serializer
  attributes :id, :status_cd, :state_cd, :date, :staging, :distribution, :king_beds, :queen_beds, :full_beds, :twin_beds, :toiletries, :contractor_names

  has_one :booking
  has_many :payouts
end

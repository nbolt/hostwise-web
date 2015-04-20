class JobSerializer < ActiveModel::Serializer
  attributes :id, :status_cd, :state_cd, :date, :staging, :distribution, :king_beds, :queen_beds, :full_beds, :twin_beds, :toiletries, :payout, :payout_integer, :payout_fractional

  has_many :contractors
  has_many :payouts
  has_one :booking
end

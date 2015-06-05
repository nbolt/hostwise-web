class JobSerializer < ActiveModel::Serializer
  attributes :id, :status_cd, :state_cd, :occasion_cd, :date, :staging, :distribution, :king_beds, :queen_beds, :full_beds, :twin_beds, :toiletries, :contractor_names, :formatted_time, :king_bed_count, :twin_bed_count, :toiletry_count, :payout_amount

  has_one :booking
  has_one :distribution_center
  has_many :payouts
  has_many :contractor_jobs
end

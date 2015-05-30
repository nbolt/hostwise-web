class DataJobsSerializer < ActiveModel::Serializer
  attributes :id, :state_cd, :date, :size, :priority, :payout, :payout_integer, :payout_fractional, :staging, :man_hours, :contractor_hours, :formatted_time

  has_one :booking, serializer: DataBookingSerializer
end

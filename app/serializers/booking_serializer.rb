class BookingSerializer < ActiveModel::Serializer
  attributes :id, :status_cd, :property_id, :cost, :original_cost, :adjusted, :refunded, :refunded_cost, :refunded_reason, :late_same_day, :late_next_day, :service_list

  has_one :property
  has_one :user
end

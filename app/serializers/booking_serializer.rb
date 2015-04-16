class BookingSerializer < ActiveModel::Serializer
  attributes :id, :property_id, :cost, :original_cost, :adjusted, :late_same_day, :late_next_day, :status_cd

  has_one :property
  has_one :user
  has_many :services
end

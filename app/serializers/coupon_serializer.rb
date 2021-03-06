class CouponSerializer < ActiveModel::Serializer
  attributes :id, :description, :code, :status, :status_cd, :discount_type, :discount_type_cd, :amount, :limit, :expiration, :display_amount, :total_applied, :total_applied_projected

  has_many :users
end

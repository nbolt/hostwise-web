class PaymentSerializer < ActiveModel::Serializer
  attributes :id, :stripe_id, :last4, :card_type, :status, :status_cd, :primary, :bank_name
end

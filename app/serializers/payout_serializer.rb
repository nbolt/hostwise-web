class PayoutSerializer < ActiveModel::Serializer
  attributes :id, :total, :amount, :adjusted, :adjusted_amount, :subtracted_amount, :additional_amount, :subtracted_reason, :additional_reason, :job_id, :user_id, :status_cd
end

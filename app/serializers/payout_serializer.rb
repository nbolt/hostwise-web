class PayoutSerializer < ActiveModel::Serializer
  attributes :id, :total, :amount, :adjusted, :subtracted_amount, :additional_amount, :job_id, :user_id, :status_cd
end

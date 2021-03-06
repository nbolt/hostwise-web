class ContractorSerializer < ActiveModel::Serializer
  attributes :id, :name, :display_phone_number, :avatar, :email, :first_name, :last_name, :phone_number, :secondary_phone,
             :role_cd, :created_at, :updated_at, :unpaid, :last_payout_date, :activation_state, :primary_payment

  has_one  :background_check
  has_one  :contractor_profile, serializer: ContractorProfileSerializer
  has_many :jobs, serializer: JobSerializer
  has_many :payouts
end

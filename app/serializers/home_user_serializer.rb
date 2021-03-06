class HomeUserSerializer < ActiveModel::Serializer
  attributes :id, :name, :first_name, :last_name, :email, :display_phone_number, :phone_number, :secondary_phone, :booking_count, :avatar, :role, :role_cd, :notification_settings, :training, :earnings, :unpaid

  has_many :payments
  has_one  :contractor_profile
end

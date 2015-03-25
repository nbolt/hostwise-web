FactoryGirl.define do |user|
	factory :user_name_1, class: User do
    first_name 'Dustin' 
    last_name 'Jones'
    email 'dustinjones593@gmail.com'
    crypted_password "$2a$10$82xOTSAyKANXSjS1K94KdOiAyJeaPTwNO32.RZ3taojJ597wyCWx2"
		salt "oaz1NpsVHaNCqza9ynGU"
  end

  factory :user_name_2, class: User do
    first_name 'Dustin' 
    email 'dustinjones594@gmail.com'
    crypted_password "$2a$10$82xOTSAyKANXSjS1K94KdOiAyJeaPTwNO32.RZ3taojJ597wyCWx2"
		salt "oaz1NpsVHaNCqza9ynGU"
  end

  factory :user_name_3, class: User do
    email 'dustinjones595@gmail.com'
    crypted_password "$2a$10$82xOTSAyKANXSjS1K94KdOiAyJeaPTwNO32.RZ3taojJ597wyCWx2"
		salt "oaz1NpsVHaNCqza9ynGU"
		phone_number "9722149321"
    after(:create) do |user|
      user.payments << create(:credit_card)
    end
  end

  factory :user_name_4, class: User do
    email 'dustinjones596@gmail.com'
    crypted_password "$2a$10$82xOTSAyKANXSjS1K94KdOiAyJeaPTwNO32.RZ3taojJ597wyCWx2"
    salt "oaz1NpsVHaNCqza9ynGU"
    phone_number "9722149321"
  end

  factory :user_name_5, class: User do
    email 'dustinjones597@gmail.com'
    crypted_password "$2a$10$82xOTSAyKANXSjS1K94KdOiAyJeaPTwNO32.RZ3taojJ597wyCWx2"
    salt "oaz1NpsVHaNCqza9ynGU"
    phone_number "9722149321"
    after(:create) do |user|
      user.payments << create(:invalid_card)
    end
  end

  factory :user_name_6, class: User do
    email 'dustinjones597@gmail.com'
    crypted_password "$2a$10$82xOTSAyKANXSjS1K94KdOiAyJeaPTwNO32.RZ3taojJ597wyCWx2"
    salt "oaz1NpsVHaNCqza9ynGU"
    phone_number "9722149321"
    after(:create) do |user|
      user.payouts << create(:payout_1)
      user.payouts << create(:payout_2)
      user.payouts << create(:payout_3)
      user.payouts << create(:payout_4)
      user.payouts << create(:payout_5)
    end
  end
end
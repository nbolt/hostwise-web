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
    role_cd 2
    association :contractor_profile, factory: :profile_1
    after(:create) do |user|
      user.payouts << create(:payout_1)
      user.payouts << create(:payout_2)
      user.payouts << create(:payout_3)
      user.payouts << create(:payout_4)
      user.payouts << create(:payout_5)
    end
  end

  factory :user_name_7, class: User do
    email 'dustinjones598@gmail.com'
    crypted_password "$2a$10$82xOTSAyKANXSjS1K94KdOiAyJeaPTwNO32.RZ3taojJ597wyCWx2"
    salt "oaz1NpsVHaNCqza9ynGU"
    phone_number "9722149321"
    role_cd 2
  end

  factory :user_name_8, class: User do
    email 'dustinjones598@gmail.com'
    crypted_password "$2a$10$82xOTSAyKANXSjS1K94KdOiAyJeaPTwNO32.RZ3taojJ597wyCWx2"
    salt "oaz1NpsVHaNCqza9ynGU"
    phone_number "9722149321"
    role_cd 2
    association :contractor_profile, factory: :profile_2
  end

  factory :user_name_9, class: User do
    email 'a_noob@gmail.com'
    crypted_password "$2a$10$82xOTSAyKANXSjS1K94KdOiAyJeaPTwNO32.RZ3taojJ597wyCWx2"
    salt "oaz1NpsVHaNCqza9ynGU"
    phone_number "2142149321"
    role_cd 1
  end

  factory :user_name_10, class: User do
    email 'dustinjones600@gmail.com'
    crypted_password "$2a$10$82xOTSAyKANXSjS1K94KdOiAyJeaPTwNO32.RZ3taojJ597wyCWx2"
    salt "oaz1NpsVHaNCqza9ynGU"
    phone_number "9722149321"
    role_cd 2
    association :contractor_profile, factory: :profile_2
  end

  factory :user_name_11, class: User do
    email 'david.siqi.kong@gmail.com'
    crypted_password "$2a$10$82xOTSAyKANXSjS1K94KdOiAyJeaPTwNO32.RZ3taojJ597wyCWx2"
    salt "oaz1NpsVHaNCqza9ynGU"
    phone_number "9722149321"
    role_cd 0
    association :contractor_profile, factory: :profile_2
  end
end
FactoryGirl.define do |user|
  factory :user_1, class: User do
    email 'test@email.com'
    crypted_password "$2a$10$82xOTSAyKANXSjS1K94KdOiAyJeaPTwNO32.RZ3taojJ597wyCWx2"
    salt "oaz1NpsVHaNCqza9ynGU"
    role_cd 2
    association :contractor_profile, factory: :profile_1
    after(:create) do |user|
      create(:payment_1, user: user)
    end
  end

  factory :user_2, class: User do
    email 'test2@email.com'
    crypted_password "$2a$10$82xOTSAyKANXSjS1K94KdOiAyJeaPTwNO32.RZ3taojJ597wyCWx2"
    salt "oaz1NpsVHaNCqza9ynGU"
    role_cd 2
    association :contractor_profile, factory: :profile_2
    after(:create) do |user|
      create(:payment_1, user: user)
    end
  end
end
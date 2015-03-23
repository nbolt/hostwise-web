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
  end
end
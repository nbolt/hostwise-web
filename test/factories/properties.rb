FactoryGirl.define do
  factory :property_1, class: Property do
    bedrooms 2
    bathrooms 2
    king_beds 0
    queen_beds 2
    full_beds 0
    twin_beds 0
    property_type :house
    zip '75093'
    address1 '4408 Lone Tree Dr.'
    city 'plano'
    state 'tx'
  end

  factory :property_2, class: Property do
  	bedrooms 1
  	bathrooms 1
  	king_beds 0
  	queen_beds 0
  	full_beds 1
  	twin_beds 0
  	property_type :condo
  	zip '75093'
    address1 '4404 Lone Tree Dr.'
    address2 '4402 Lone Tree Dr.'
    city 'plano'
    state 'tx'
  end

  factory :property_3, class: Property do
  	bedrooms 9
  	bathrooms 7
  	king_beds 5
  	queen_beds 3
  	full_beds 0
  	twin_beds 1
  	property_type :house
  end

  factory :property_4, class: Property do
  	bedrooms 9
  	bathrooms 7
    king_beds 5
    queen_beds 3
    full_beds 0
    twin_beds 1
  	property_type :house
  	lat 33.99766
  	lng -118.47181
    association :user, factory: :user_name_3
  end

  factory :property_5, class: Property do
    bedrooms 9
    bathrooms 7
    king_beds 5
    queen_beds 3
    full_beds 0
    twin_beds 1
    property_type :house
    lat 33.99766
    lng -118.47181
    association :user, factory: :user_name_5
  end
end
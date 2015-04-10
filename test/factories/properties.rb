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
    active true
    after(:create) do |property|
      property.bookings << create(:booking_first)
      property.bookings << create(:booking_second)
    end
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
    address2 '#4'
    city 'plano'
    state 'tx'
    active true
    after(:create) do |property|
      property.property_photos << create(:property_photo_1)
    end
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
  	lat 53.349805
  	lng -6.260310
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

  factory :property_6, class: Property do
    bedrooms 1
    bathrooms 1
    king_beds 0
    queen_beds 0
    full_beds 1
    twin_beds 0
    property_type :condo
    zip '90023'
    address1 '4404 Lone Tree Dr.'
    address2 '4402 Lone Tree Dr.'
    city 'plano'
    state 'tx'
  end

  factory :property_8, class: Property do
    bedrooms 2
    bathrooms 2
    king_beds 0
    queen_beds 2
    full_beds 0
    twin_beds 0
    property_type :house
    address1 '3100 Wynwood Ln'
    city 'los angeles'
    state 'CA'
    zip '90023'
  end

  factory :property_9, class: Property do
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
    active true
    after(:create) do |property|
      property.bookings << create(:booking_first)
      property.bookings << create(:booking_second)
    end
  end

  factory :property_10, class: Property do
    bedrooms 2
    bathrooms 2
    king_beds 0
    queen_beds 2
    full_beds 0
    twin_beds 0
    property_type :house
    zip '90403'
    address1 '2025 Wilshire Blvd'
    city 'santa monica'
    state 'ca'
    active true
    after(:create) do |property|
      property.bookings << create(:booking_first)
      property.bookings << create(:booking_second)
    end
  end
end
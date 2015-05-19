FactoryGirl.define do
  factory :property_1, class: Property do
    bedrooms 1
    bathrooms 1
    king_beds 0
    queen_beds 1
    full_beds 0
    twin_beds 0
    property_type :condo
    zip '90025'
    address1 '1317 S Bundy Dr'
    city 'Los Angeles'
    state 'CA'
    active true
  end

  factory :property_2, class: Property do
    bedrooms 3
    bathrooms 3
    king_beds 0
    queen_beds 3
    full_beds 0
    twin_beds 0
    property_type :house
    zip '90291'
    address1 '338 Rennie Ave'
    city 'Los Angeles'
    state 'CA'
    active true
  end
end
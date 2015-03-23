FactoryGirl.define do
  factory :property, class: Property do
    bedrooms 2
    bathrooms 2
    property_type :house
  end
end
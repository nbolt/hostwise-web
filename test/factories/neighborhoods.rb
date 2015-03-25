FactoryGirl.define do |neighborhood|
	factory :neighborhood_1, class: Neighborhood do
		name 'Preston Meadow'
		#association :county, factory: :county_1
  end

  factory :neighborhood_2, class: Neighborhood do
		name 'los angeles'
		#association :county, factory: :county_1
  end
end

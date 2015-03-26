FactoryGirl.define do |distribution_center|
	factory :venice_center, class: DistributionCenter do
		name 'Venice Warehouse'
		address1 '1020 Lake St'		
		address2 '#9'
		city 'Los Angeles'
		state 'CA'
		zip '90291'
	end

	factory :city_center, class: DistributionCenter do
		name 'Mid-City Warehouse'
		address1 '3430 South La Brea Avenue'
		city 'Los Angeles'
		state 'CA'
		zip '90016'
	end
end

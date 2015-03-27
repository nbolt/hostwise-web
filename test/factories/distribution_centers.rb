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

	factory :no_zip, class: DistributionCenter do
		name 'no-zip'
	end

	factory :plano_center, class: DistributionCenter do
		name 'Plano Warehouse'
		address1 '4408 Lone Tree Dr'	
		city 'plano'
		state 'TX'
		zip '75093'
	end

	factory :invalid_center, class: DistributionCenter do
		name 'Plano Warehouse'
		address1 '4420 Lone Tree Dr'	
		city 'los angeles'
		state 'TX'
		zip '75423'
	end
end

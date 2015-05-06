FactoryGirl.define do |zip|
	factory :zip_1, class: ZipCode do
		code '75093'
		association :city, factory: :city_1
		association :neighborhood, factory: :neighborhood_1
	end

	factory :zip_2, class: ZipCode do
		code '90023'
		association :city, factory: :city_2
	end

	factory :zip_3, class: ZipCode do
		code '90291'
		association :city, factory: :city_2
	end
end

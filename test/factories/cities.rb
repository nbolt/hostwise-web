FactoryGirl.define do |city|
	factory :city_1, class: City do
		name 'plano'		
		association :county, factory: :county_1
	end

	factory :city_2, class: City do
		name 'los angeles'		
		association :county, factory: :county_2
	end
end

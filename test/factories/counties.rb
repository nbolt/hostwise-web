FactoryGirl.define do |counties|
	factory :county_1, class: County do
		name 'Collin County'		
		association :state, factory: :state_1
	end

	factory :county_2, class: County do
		name 'LA County'		
		association :state, factory: :state_2
	end
end

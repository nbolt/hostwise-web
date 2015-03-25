FactoryGirl.define do |state|
	factory :state_1, class: State do
		name 'texas'
		abbr 'tx'		
	end

	factory :state_2, class: State do
		name 'california'
		abbr 'ca'		
	end
end

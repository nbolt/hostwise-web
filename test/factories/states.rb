FactoryGirl.define do |state|
	factory :state_1, class: State do
		name 'texas'
		abbr 'tx'		
	end

	factory :state_2, class: State do
		name 'california'
		abbr 'ca'		
		created_at Date.new(3,3,3)
		updated_at Date.new(4,4,4)
		id 0
	end
end

FactoryGirl.define do |profile|
	factory :profile_1, class: ContractorProfile do
		position_cd 1
		address1 '1317 S Bundy Dr'
		city 'Los Angeles'
		state 'CA'
		zip '90025'
	end

	factory :profile_2, class: ContractorProfile do
		position_cd 2
		address1 '1317 S Bundy Dr'
		city 'Los Angeles'
		state 'CA'
		zip '90025'
	end

	factory :profile_3, class: ContractorProfile do
		position_cd 0
		address1 '1317 S Bundy Dr'
		city 'Los Angeles'
		state 'CA'
		zip '90025'
	end

	factory :profile_4, class: ContractorProfile do
		position_cd 3
		address1 '1317 S Bundy Dr'
		city 'Los Angeles'
		state 'CA'
		zip '90025'
	end

	factory :invalid_profile, class: ContractorProfile do
		position_cd 3
		address1 '1317 S Bundy Dr'
		city 'Los Angeles'
		state 'VA'
		zip '93325'
	end
end

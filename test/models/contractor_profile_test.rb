require "test_helper"

describe ContractorProfile do
	it 'should return the right position' do
		profile_1 = create(:profile_1)
		profile_1.current_position.must_equal ({:id => '1', :text => :TRAINEE})
		profile_2 = create(:profile_2)
		profile_2.current_position.must_equal ({:id => '2', :text => :CONTRACTOR})
	end

	it 'should handle firing correctly' do
		user_name_6 = nil
		VCR.use_cassette('create_user_name_6') { user_name_6 = create(:user_name_6) }
		
		user_name_6.must_equal user_name_6

		#profile_1 = create(:profile_1)
		#profile_1.position_cd = 2
		#profile_1.position = :fired
		#profile_1.save
		#profile_1.handle_fired
	end
end
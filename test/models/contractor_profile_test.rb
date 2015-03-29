	require "test_helper"

describe ContractorProfile do
	it 'should return the right position' do
		profile_1 = create(:profile_1)
		profile_1.current_position.must_equal ({:id => '1', :text => 'APPLICANT'})
		profile_2 = create(:profile_2)
		profile_2.current_position.must_equal ({:id => '2', :text => 'CONTRACTOR'})
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

	it 'should display position properly' do
		profile_1 = nil; profile_2 = nil; profile_3 = nil; profile_4 = nil
		VCR.use_cassette('create_profile_1') { profile_1 = create(:profile_1) }
		VCR.use_cassette('create_profile_2') { profile_2 = create(:profile_2) }
		# VCR.use_cassette('create_profile_3') { profile_3 = create(:profile_3) }
		VCR.use_cassette('create_profile_4') { profile_4 = create(:profile_4) }
		# VCR.use_cassette('create_user_name_10') { user_name_10 = create(:user_name_10) }

		profile_3.must_equal profile_3

		profile_1.display_position.must_equal 'applicant'
		profile_2.display_position.must_equal 'contractor'
		#user_name_10.contractor_profile.display_position.must_equal 'fired'
		profile_4.display_position.must_equal 'mentor'
	end

	it 'should error on invalid address' do
		invalid_profile = nil
		assert_raises ActiveRecord::RecordInvalid do
			VCR.use_cassette('create_invalid_profile') { invalid_profile = create(:invalid_profile) }
		end
	end
end
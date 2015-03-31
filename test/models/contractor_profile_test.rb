require "test_helper"

describe ContractorProfile do
	it 'should return the right position' do
		profile_1 = create(:profile_1)
		profile_1.current_position.must_equal ({:id => '1', :text => 'APPLICANT'})
		profile_2 = create(:profile_2)
		profile_2.current_position.must_equal ({:id => '2', :text => 'CONTRACTOR'})
	end

	it 'should display position properly' do
		profile_1 = nil; profile_2 = nil; profile_3 = nil; profile_4 = nil, user_name_10 = nil
		VCR.use_cassette('create_profile_1') { profile_1 = create(:profile_1) }
		VCR.use_cassette('create_profile_2') { profile_2 = create(:profile_2) }
		profile_2.must_equal profile_2
		VCR.use_cassette('create_user_name_10') { user_name_10 = create(:user_name_10) }
		VCR.use_cassette('create_profile_4') { profile_4 = create(:profile_4) }

		profile_1.display_position.must_equal 'applicant'
		profile_2.display_position.must_equal 'contractor'
		profile_4.display_position.must_equal 'mentor'

		profile_2.position_cd = 0

		profile_2.display_position.must_equal 'fired'
		
		# user_name_10.activation_state.must_equal 'deactivated'

	end

	it 'should return if test session completed' do
		profile_1 = nil, profile_2 = nil
		VCR.use_cassette('create_profile_1') { profile_1 = create(:profile_1) }
		VCR.use_cassette('create_profile_2') { profile_2 = create(:profile_2) }

		profile_2.test_session_completed.must_equal true
	end

	it 'should error on invalid address' do
		invalid_profile = nil
		assert_raises ActiveRecord::RecordInvalid do
			VCR.use_cassette('create_invalid_profile') { invalid_profile = create(:invalid_profile) }
		end
	end

	it 'should create stripe recipient' do
		profile_1 = nil, stripe_recipient = nil
		VCR.use_cassette('create_profile_1') { profile_1 = create(:profile_1) }
		#profile_1.save
	end
end

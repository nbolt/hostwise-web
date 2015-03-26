require "test_helper"

describe User do 
	it 'names correctly' do
		user_name_1 = nil; user_name_2 = nil; user_name_3 = nil

		VCR.use_cassette('create_user_name_1') { user_name_1 = create(:user_name_1) }
		user_name_1.name.must_equal 'Dustin J.'

		VCR.use_cassette('create_user_name_2') { user_name_2 = create(:user_name_2) }
		user_name_2.name.must_equal 'Dustin'

		VCR.use_cassette('create_user_name_3') { user_name_3 = create(:user_name_3) }
		user_name_3.name.must_equal ''
	end

	it 'phone numbers correctly' do
		user_name_3 = nil
		VCR.use_cassette('create_user_name_3') { user_name_3 = create(:user_name_3) }
		user_name_3.display_phone_number.must_equal '(972) 214-9321'
	end

	it 'shows correct earnings' do
		user_name_6 = nil
		VCR.use_cassette('create_user_name_6') { user_name_6 = create(:user_name_6) }
		user_name_6.earnings.must_equal 38
		user_name_6.unpaid.must_equal 34
	end

	it 'shows avatar correctly' do
		user_name_1 = nil
		VCR.use_cassette('create_user_name_1') { user_name_1 = create(:user_name_1) }
		user_name_1.avatar.must_equal  "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(user_name_1.email)}.jpg?d=https%3A%2F%2Fs3.amazonaws.com%2Fhostwise-production%2Fgeneric_user.png"
	end

	it 'shows correct notification settings' do
		user_name_1 = nil
		VCR.use_cassette('create_user_name_1') { user_name_1 = create(:user_name_1) }
		user_name_1.notification_settings.must_equal({:new_open_job=>{}, :job_claim_confirmation=>{}, :service_reminder=>{}, :booking_confirmation=>{}, :service_completion=>{}, :porter_arrived=>{}, :property_added=>{}, :porter_en_route=>{}})
	end

	it 'shows correct contractors' do
		user_name_7 = nil
		VCR.use_cassette('create_user_name_7') { user_name_7 = create(:user_name_7) }
		#user_name_7.must_equal user_name_7
		#User.contractors.must_equal ''
	end
end
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

	it 'should drop jobs sucessfully' do
		venice_center = nil; city_center = nil; user_name_6 = nil; job_2 = nil; job_3 = nil; job_1 = nil

		VCR.use_cassette('create_venice_center') { venice_center = create(:venice_center) }
		VCR.use_cassette('create_city_center') { city_center = create(:city_center) }
		venice_center.must_equal venice_center
		city_center.must_equal city_center
		
		VCR.use_cassette('create_user_name_6') { user_name_6 = create(:user_name_6) }
		VCR.use_cassette('create_job_1') { job_1 = create(:job_1) }
		VCR.use_cassette('create_job_2') { job_2 = create(:job_2) }
		VCR.use_cassette('create_job_3') { job_3 = create(:job_3) }

		user_name_6.claim_job job_1
		user_name_6.claim_job job_2
		user_name_6.claim_job job_3
		user_name_6.drop_job user_name_6.jobs[0]
		user_name_6.jobs.count.must_equal 6
	end

	it 'should return if deactivated or not' do
		user_name_6 = nil
		VCR.use_cassette('create_user_name_6') { user_name_6 = create(:user_name_6) }
		user_name_6.deactivated?.must_equal false
	end

	it 'should show contractors based on search' do
		user_name_6 = nil, user_name_8 = nil
		VCR.use_cassette('create_user_name_6') { user_name_6 = create(:user_name_6) }
		VCR.use_cassette('create_user_name_8') { user_name_8 = create(:user_name_8) }
		
		User.contractors('dustinjones598@gmail.com')[0].email.must_equal 'dustinjones598@gmail.com'
		User.contractors('dustinjones598@gmail.com').size.must_equal 1
		
		User.contractors().size.must_equal 2
	end

	it 'should show hosts based on search' do
		user_name_9 = nil
		VCR.use_cassette('create_user_name_9') { user_name_9 = create(:user_name_9) }
		#User.hosts('a_noob@')[0].email.must_equal 'a_noob@gmail.com'
		User.hosts().size.must_equal 1
	end

	it 'show quiz info' do
		venice_center = nil; city_center = nil; user_name_6 = nil; job_2 = nil; job_3 = nil; job_1 = nil

		VCR.use_cassette('create_venice_center') { venice_center = create(:venice_center) }
		VCR.use_cassette('create_city_center') { city_center = create(:city_center) }
		venice_center.must_equal venice_center
		city_center.must_equal city_center
		
		VCR.use_cassette('create_user_name_6') { user_name_6 = create(:user_name_6) }
		VCR.use_cassette('create_job_1') { job_1 = create(:job_1) }
		VCR.use_cassette('create_job_2') { job_2 = create(:job_2) }
		VCR.use_cassette('create_job_3') { job_3 = create(:job_3) }

		user_name_6.claim_job job_1
		user_name_6.claim_job job_2
		user_name_6.claim_job job_3

		user_name_6.show_quiz.must_equal true
	end
end
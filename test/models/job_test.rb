require "test_helper"

describe Job do
	it 'searches future jobs properly' do
		job_1 = Job.create(date: Date.today)
		job_2 = Job.create(date: Date.today + 1.years, full_beds: 9)
		Job.all.future[0].full_beds.must_equal 9
		#Job.all.future_from_today[0].full_beds.must_equal 9
	end

	it 'searches for open jobs properly' do
		#job_1 = Job.create(status_cd: 0, full_beds: 5)
		#job_2 = Job.create(status_cd: 0, full_beds: 7)
		#Job.all.open[0].must_equal ''
	end

	it 'displays payouts properly' do
		job_1 = nil
		VCR.use_cassette('create_job_1') { job_1 = create(:job_1) }
		job_1.payout_integer.must_equal 20
		job_1.payout_fractional.must_equal 0
	end

	it 'formats date correctly' do
		job_1 = nil
		VCR.use_cassette('create_job_1') { job_1 = create(:job_1) }
		job_1.formatted_date.must_equal '04/18/2015'
	end

	it 'displays if it has toiletries' do
		job_1 = nil
		VCR.use_cassette('create_job_1') { job_1 = create(:job_1) }
		job_1.has_toiletries?.must_equal false
		job_1.has_linens?.must_equal false
		job_1.staging.must_equal false
	end

	it 'shows jobs where priority contractor' do
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
		date_1_jobs = user_name_6.jobs.on_date(Date.new(2015, 4, 18))
		date_2_jobs = user_name_6.jobs.on_date(Date.new(2015, 4, 19))

		date_2_jobs.standard[0].priority(user_name_6).must_equal 1
		date_2_jobs.distribution.pickup[0].priority(user_name_6).must_equal 0
		date_2_jobs.distribution.dropoff[0].priority(user_name_6).must_equal 2

		date_2_jobs.distribution.pickup[0].next_job(user_name_6).must_equal date_2_jobs.standard[0]
		date_2_jobs.distribution.dropoff[0].prev_job(user_name_6).must_equal date_2_jobs.standard[0]
	end

	it 'displays proper payout' do
		job_2 = nil; user_name_6 = nil, job_5 = nil, user_name_10 = nil, user_name_11 = nil
		VCR.use_cassette('create_user_name_6') { user_name_6 = create(:user_name_6) }
		VCR.use_cassette('create_user_name_10') { user_name_10 = create(:user_name_10) }
		VCR.use_cassette('create_user_name_11') { user_name_11 = create(:user_name_11) }
		VCR.use_cassette('create_job_2') { job_2 = create(:job_2) }
		VCR.use_cassette('create_job_5') { job_5 = create(:job_5) }
		job_2.payout(user_name_6).must_equal 20
		job_2.payout.must_equal 70
		job_5.payout(user_name_10).must_equal 38.5
		job_5.payout(user_name_11).must_equal 35	
		job_5.payout.must_equal 38.5
	end

	it 'shows correct man hours' do
		job_2 = nil; user_name_6 = nil, job_5 = nil
		VCR.use_cassette('create_user_name_6') { user_name_6 = create(:user_name_6) }
		VCR.use_cassette('create_job_2') { job_2 = create(:job_2) }
		VCR.use_cassette('create_job_5') { job_5 = create(:job_5) }
		job_2.contractor_hours(user_name_6).must_equal 0
	end

	it 'shows minimum job size' do
		job_2 = nil
		VCR.use_cassette('create_job_2') { job_2 = create(:job_2) }
		job_2.minimum_job_size.must_equal 1
	end

	it 'shows if first job of day correctly' do
		venice_center = nil; city_center = nil; user_name_8 = nil; job_2 = nil; job_3 = nil; job_1 = nil

		VCR.use_cassette('create_venice_center') { venice_center = create(:venice_center) }
		VCR.use_cassette('create_city_center') { city_center = create(:city_center) }
		venice_center.must_equal venice_center
		city_center.must_equal city_center
		
		VCR.use_cassette('create_user_name_8') { user_name_8 = create(:user_name_6) }
		VCR.use_cassette('create_job_1') { job_1 = create(:job_1) }
		VCR.use_cassette('create_job_2') { job_2 = create(:job_2) }
		VCR.use_cassette('create_job_3') { job_3 = create(:job_3) }

		user_name_8.claim_job job_1
		user_name_8.claim_job job_2
		user_name_8.claim_job job_3

		user_name_8.jobs[0].first_job_of_day(user_name_8).must_equal false
		user_name_8.jobs[0].previous_team_job(user_name_8).must_equal false
	end

	it 'status shows properly' do
		job_6 = nil, job_7 = nil, job_8 = nil
		VCR.use_cassette('create_job_6') { job_6 = create(:job_6) }
		VCR.use_cassette('create_job_7') { job_7 = create(:job_7) }
		VCR.use_cassette('create_job_8') { job_8 = create(:job_8) }

		job_6.complete?.must_equal false
		job_6.in_progress?.must_equal false
		job_6.not_complete?.must_equal true

		job_7.complete?.must_equal false
		job_7.in_progress?.must_equal true
		job_7.not_complete?.must_equal true

		job_8.complete?.must_equal true
		job_8.in_progress?.must_equal false
		job_8.not_complete?.must_equal false
	end

	it 'should complete properly' do
		job_7 = nil
		VCR.use_cassette('create_job_7') { job_7 = create(:job_7) }
		job_7.complete!
		job_7.status_cd.must_equal 3
	end

	it 'should return proper checklist' do
		venice_center = nil; city_center = nil; user_name_8 = nil; job_2 = nil; job_3 = nil; job_1 = nil

		VCR.use_cassette('create_venice_center') { venice_center = create(:venice_center) }
		VCR.use_cassette('create_city_center') { city_center = create(:city_center) }
		venice_center.must_equal venice_center
		city_center.must_equal city_center
		
		VCR.use_cassette('create_user_name_8') { user_name_8 = create(:user_name_6) }
		VCR.use_cassette('create_job_1') { job_1 = create(:job_1) }
		VCR.use_cassette('create_job_2') { job_2 = create(:job_2) }
		VCR.use_cassette('create_job_3') { job_3 = create(:job_3) }

		user_name_8.claim_job job_1
		user_name_8.claim_job job_2
		user_name_8.claim_job job_3
		
		user_name_8.jobs[0].checklist.has_attribute?(:kitchen_photo).must_equal true
		user_name_8.jobs[0].checklist.has_attribute?(:bathroom_photo).must_equal true
		user_name_8.jobs[0].checklist.has_attribute?(:bedroom_photo).must_equal true
	end

	it 'should return proper primary info' do
		venice_center = nil; city_center = nil; user_name_8 = nil; job_2 = nil; job_3 = nil; job_1 = nil

		VCR.use_cassette('create_venice_center') { venice_center = create(:venice_center) }
		VCR.use_cassette('create_city_center') { city_center = create(:city_center) }
		venice_center.must_equal venice_center
		city_center.must_equal city_center
		
		VCR.use_cassette('create_user_name_8') { user_name_8 = create(:user_name_6) }
		VCR.use_cassette('create_job_1') { job_1 = create(:job_1) }
		VCR.use_cassette('create_job_2') { job_2 = create(:job_2) }
		VCR.use_cassette('create_job_3') { job_3 = create(:job_3) }

		user_name_8.claim_job job_1
		user_name_8.claim_job job_2
		user_name_8.claim_job job_3
		
		# user_name_8.jobs[0].checklist
		user_name_8.jobs[0].primary_contractor.email.must_equal 'dustinjones597@gmail.com'
		user_name_8.jobs[0].primary(user_name_8).must_equal true
	end

	it 'should show future jobs' do
		job_9 = nil, job_10 = nil, job_11 = nil, job_12 = nil

		VCR.use_cassette('create_job_9') { job_9 = create(:job_9) }
		VCR.use_cassette('create_job_10') { job_10 = create(:job_10) }
		VCR.use_cassette('create_job_11') { job_11 = create(:job_11) }
		VCR.use_cassette('create_job_12') { job_12 = create(:job_12) }

		# Job.future.size.must_equal 4
	end

	it 'returns if job is tomorrow' do
		job_12 = nil, job_13 = nil
		VCR.use_cassette('create_job_12') { job_12 = create(:job_12) }
		VCR.use_cassette('create_job_13') { job_13 = create(:job_13) }
		job_12.tomorrow?(Date.today).must_equal false
		job_13.tomorrow?(Date.today).must_equal true
	end

	it 'returns cant access seconds' do
		job_14 = nil
		VCR.use_cassette('create_job_14') { job_14 = create(:job_14) }
		#job_14.cant_access_seconds_left.must_equal 0
	end

end



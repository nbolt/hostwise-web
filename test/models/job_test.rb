require "test_helper"

describe Job do
	it 'displays payouts properly' do
		job_1 = create(:job_1)
		job_1.payout_integer.must_equal 20
		job_1.payout_fractional.must_equal 0
	end

	it 'formats date correctly' do
		job_1 = create(:job_1)
		job_1.formatted_date.must_equal '04/18/2015'
	end

	it 'displays if it has toiletries' do
		job_1 = create(:job_1)
		job_1.has_toiletries?.must_equal false
		job_1.has_linens?.must_equal false
		job_1.staging.must_equal false
	end

	it 'shows jobs where priority contractor' do
		venice_center = create(:venice_center)
		city_center = create(:city_center)
		venice_center.must_equal venice_center
		city_center.must_equal city_center
		
		user_name_6 = create(:user_name_6)
		job_2 = create(:job_2)
		user_name_6.claim_job job_2
		user_name_6.jobs.standard[0].priority(user_name_6).must_equal 1
	end

	it 'displays proper payout' do
		user_name_1 = create(:user_name_1)
		# job_2 = create(:job_2)
		# job_2.payout(user_name_1).must_equal 130
	end
end



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
end



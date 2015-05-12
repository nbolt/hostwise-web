require "test_helper"

describe Payout do
	it 'processes correctly' do
		VCR.use_cassette('create_payout_1') { payout_1 = create(:payout_1) }
		# VCR.use_cassette('create_payout_process') { payout_process = payout_1.process! }	
		# payout_process.must_equal '' 
	end
end

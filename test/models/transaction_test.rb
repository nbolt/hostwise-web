require "test_helper"

describe Transaction do 
	it 'should show completed transactions' do
		user_name_6 = nil
		VCR.use_cassette('create_user_name_6') {user_name_6 = create(:user_name_6)}
		#Transaction.completed(user_name_6, Date.new(2012, 2, 2), Date.new(2014, 4, 4))
	end
end
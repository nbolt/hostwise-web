require "test_helper"

describe User do 
	it 'names correctly' do
		user_name_1 = create(:user_name_1)
		user_name_1.name.must_equal 'Dustin J.'

		user_name_2 = create(:user_name_2)
		user_name_2.name.must_equal 'Dustin'

		user_name_3 = create(:user_name_3)
		user_name_3.name.must_equal ''
	end

	it 'phone numbers correctly' do
		user_name_3 = create(:user_name_3)
		user_name_3.display_phone_number.must_equal '(972) 214-9321'
	end

	it 'shows correct earnings' do
		user_name_6 = create(:user_name_6)
		user_name_6.earnings.must_equal 38
		user_name_6.unpaid.must_equal 34
	end
end
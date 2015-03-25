require "test_helper"

describe City do
	it 'should have the right state' do
		city_2 = create(:city_2)

		city_2.state.must_equal State.new(:id => 0, :name => 'california', :abbr => 'ca', :created_at => Date.new(3,3,3), :updated_at => Date.new(4,4,4))
	end
end
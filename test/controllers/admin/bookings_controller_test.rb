require 'test_helper'

describe Admin::BookingsController do
  it 'index' do
    booking_cancelled = nil
    VCR.use_cassette('create_booking_cancelled') { booking_cancelled = create(:booking_cancelled) }

    #get(:index, :id => 4)
    #assert_response :success
  end
end
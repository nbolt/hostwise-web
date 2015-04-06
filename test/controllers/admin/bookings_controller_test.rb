require 'test_helper'

describe Admin::BookingsController do
  it 'index' do
    booking_cancelled = nil
    VCR.use_cassette('create_booking_cancelled') { booking_cancelled = create(:booking_cancelled) }

    get(:index, {'id' => booking_cancelled.id})
    #assert_response :success
    #assert_not_nil assigns(:bookings)
  end
end
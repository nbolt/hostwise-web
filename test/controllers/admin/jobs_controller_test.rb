require "test_helper"
 
describe Admin::JobsController do
  it 'index' do
  end

  it 'booking_cost' do
    booking_cancelled = nil
    VCR.use_cassette('create_booking_cancelled') { booking_cancelled = create(:booking_cancelled) }
    get(:booking_cost, :id => booking_cancelled.id)
    #assert_response :success
  end

  it 'add_contractor' do
  end

  it 'remove_contractor' do
  end

  it 'add_service' do
  end
end
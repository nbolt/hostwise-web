require "test_helper"

describe Booking do
  it 'calculates cost correctly' do
    booking_cancelled = create(:booking_cancelled)
    booking_cancelled.cost.must_equal 25

    booking_active_1 = create(:booking_active_1)
    booking_active_1.cost.must_equal 130

    booking_active_2 = create(:booking_active_2)
    booking_active_2.cost.must_equal 75

    booking_active_3 = create(:booking_active_3)
    booking_active_3.cost.must_equal 220

    booking_late_next_day = create(:booking_late_next_day)
    booking_late_next_day.cost.must_equal 245

    booking_late_same_day = create(:booking_late_same_day)
    booking_late_same_day.cost.must_equal 245

    booking_first_booking_discount = create(:booking_first_booking_discount)
    booking_first_booking_discount.cost.must_equal 20
  end

  it 'formats date correctly' do
  	booking_date = create(:booking_dated)
  	booking_date.formatted_date.must_equal '03/23/2014'
  end

  it 'same day cancels correctly' do
  	booking_same_day_cancellation = create(:booking_lat_lng)
  	booking_same_day_cancellation.same_day_cancellation.must_equal false
  end

  describe 'payments' do
    before do
      @booking = create(:booking_active_4)
      @booking.pending!
      customer = nil; card = nil

      VCR.use_cassette('booking_create_stripe_customer') { @booking.user.create_stripe_customer }
      VCR.use_cassette('booking_customer_retrieval') { customer = Stripe::Customer.retrieve @booking.user.stripe_customer_id } 
      VCR.use_cassette('booking_create_card') { card = customer.sources.create(card: {exp_month:1,exp_year:20,number:'4242424242424242'}) }

      @booking.user.payments.first.update_attribute :stripe_id, card.id
      @booking.payment = @booking.user.payments.first
    end

    it 'charges correctly' do
      VCR.use_cassette('booking_charge') { @booking.charge! }
      @booking.payment_status.must_equal :completed
    end

  end

end
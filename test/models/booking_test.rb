require "test_helper"

describe Booking do
  it 'calculates cost correctly' do
    booking_cancelled = nil; booking_active_1 = nil; booking_active_2 = nil; booking_active_3 = nil
    booking_late_same_day = nil; booking_late_next_day = nil; booking_first_booking_discount = nil

    VCR.use_cassette('create_booking_cancelled') { booking_cancelled = create(:booking_cancelled) }
    booking_cancelled.cost.must_equal 25

    VCR.use_cassette('create_booking_active_1') { booking_active_1 = create(:booking_active_1) }
    booking_active_1.cost.must_equal 130

    VCR.use_cassette('create_booking_active_2') { booking_active_2 = create(:booking_active_2) }
    booking_active_2.cost.must_equal 75

    VCR.use_cassette('create_booking_active_3') { booking_active_3 = create(:booking_active_3) }
    booking_active_3.cost.must_equal 220

    VCR.use_cassette('create_booking_late_next_day') { booking_late_next_day = create(:booking_late_next_day) }
    booking_late_next_day.cost.must_equal 245

    VCR.use_cassette('create_booking_late_same_day') { booking_late_same_day = create(:booking_late_same_day) }
    booking_late_same_day.cost.must_equal 245

    VCR.use_cassette('create_booking_first_booking_discount') { booking_first_booking_discount = create(:booking_first_booking_discount) }
    booking_first_booking_discount.cost.must_equal 20
  end

  it 'formats date correctly' do
    booking_date = nil
  	VCR.use_cassette('create_booking_dated') { booking_date = create(:booking_dated) }
  	booking_date.formatted_date.must_equal '03/23/2014'
  end

  it 'same day cancels correctly' do
    booking_same_day_cancellation = nil; booking_not_today = nil

  	VCR.use_cassette('create_booking_lat_lng') { booking_same_day_cancellation = create(:booking_lat_lng) }
  	booking_same_day_cancellation.same_day_cancellation.must_equal true

    VCR.use_cassette('create_booking_not_today') { booking_not_today = create(:booking_not_today) }
    booking_not_today.same_day_cancellation.must_equal false
  end

  describe 'payments' do
    before do
      @booking = nil; @boobing_2 = nil; customer = nil; card = nil

      VCR.use_cassette('create_booking_active_4') { @booking = create(:booking_active_4) }
      @booking.pending!

      VCR.use_cassette('booking_create_stripe_customer') { @booking.user.create_stripe_customer }
      VCR.use_cassette('booking_customer_retrieval') { customer = Stripe::Customer.retrieve @booking.user.stripe_customer_id } 
      VCR.use_cassette('booking_create_card') { card = customer.sources.create(card: {exp_month:1,exp_year:20,number:'4242424242424242'}) }

      @booking.user.payments.first.update_attribute :stripe_id, card.id
      @booking.payment = @booking.user.payments.first

      VCR.use_cassette('create_booking_active_5') { @booking_2 = create(:booking_active_5) }
      @booking_2.pending!

      VCR.use_cassette('booking_create_stripe_customer_2') { @booking_2.user.create_stripe_customer }
      VCR.use_cassette('booking_customer_retrieval_2') { customer = Stripe::Customer.retrieve @booking_2.user.stripe_customer_id } 
      VCR.use_cassette('booking_create_card_2') { card = customer.sources.create(card: {exp_month:1,exp_year:20,number:'4000000000000341'}) }

      @booking_2.user.payments.first.update_attribute :stripe_id, card.id
      @booking_2.payment = @booking_2.user.payments.first
    end

    it 'charges correctly' do
      VCR.use_cassette('booking_charge') { @booking.charge! }
      @booking.payment_status.must_equal :completed

      VCR.use_cassette('booking_charge_2') { @booking_2.charge! }
      @booking_2.payment_status.must_equal :pending
      @booking_2.last_transaction.status.must_equal :failed
    end

  end

end
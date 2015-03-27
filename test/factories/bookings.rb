FactoryGirl.define do |booking|
  factory :booking_cancelled, class: Booking do
    status_cd 2
    association :property, factory: :property_1
  end

  factory :booking_active_1, class: Booking do
    status_cd 1
    association :property, factory: :property_1
    after(:create) do |booking|
    	booking.services << create(:cleaning)
    	booking.services << create(:linens)
    end
  end

  factory :booking_active_2, class: Booking do
    status_cd 1
    association :property, factory: :property_2
    after(:create) do |booking|
    	booking.services << create(:cleaning)
    	booking.services << create(:linens)
    	booking.services << create(:toiletries)
    end
  end

  factory :booking_active_3, class: Booking do
    status_cd 1
    association :property, factory: :property_3
    after(:create) do |booking|
    	booking.services << create(:pool)
    	booking.services << create(:patio)
    	booking.services << create(:windows)
    	booking.services << create(:preset)
    end
  end

  factory :booking_active_4, class: Booking do
    status_cd 1
    association :property, factory: :property_4
    after(:create) do |booking|
      booking.services << create(:pool)
      booking.services << create(:patio)
      booking.services << create(:windows)
      booking.services << create(:preset)
    end
  end

  factory :booking_late_next_day, class: Booking do
    status_cd 1
    late_next_day true
    association :property, factory: :property_3
    after(:create) do |booking|
    	booking.services << create(:pool)
    	booking.services << create(:patio)
    	booking.services << create(:windows)
    	booking.services << create(:preset)
    end
  end

  factory :booking_late_same_day, class: Booking do
    status_cd 1
    late_same_day true
    association :property, factory: :property_3
    after(:create) do |booking|
    	booking.services << create(:pool)
    	booking.services << create(:patio)
    	booking.services << create(:windows)
    	booking.services << create(:preset)
    end
  end

  factory :booking_dated, class: Booking do
  	association :property, factory: :property_3
  	date Date.new(2014, 3, 23)
  end

  factory :booking_lat_lng, class: Booking do
  	association :property, factory: :property_4
  	date Timezone::Zone.new(zone: "Europe/Dublin").time(Time.now).to_date
  end

  factory :booking_first_booking_discount, class: Booking do
    status_cd 1
    first_booking_discount true
    association :property, factory: :property_3
    after(:create) do |booking|
    	booking.services << create(:pool)
    	booking.services << create(:patio)
    	booking.services << create(:windows)
    	booking.services << create(:preset)
    end
  end

  factory :booking_zero_cost, class: Booking do
    status_cd 1
    first_booking_discount true
    association :property, factory: :property_1
  end


  factory :booking_active_5, class: Booking do
    status_cd 1
    association :property, factory: :property_5
    after(:create) do |booking|
      booking.services << create(:pool)
      booking.services << create(:patio)
      booking.services << create(:windows)
      booking.services << create(:preset)
    end
  end

  factory :booking_not_today, class: Booking do
    status_cd 2
    association :property, factory: :property_1
    date Date.new(3,3,3)
  end

  factory :booking_first, class: Booking do
    status_cd 1
    association :property, factory: :property_2
    date Date.today + 1.days
  end

  factory :booking_second, class: Booking do
    status_cd 1
    association :property, factory: :property_2
    date Date.today + 2.days
  end
end
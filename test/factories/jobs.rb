FactoryGirl.define do |job|
	factory :job_1, class: Job do
		association :booking, factory: :booking_cancelled
		date Date.new(2015, 4, 18)
    status_cd 1
  end

  factory :job_2, class: Job do
		association :booking, factory: :booking_active_1
		date Date.new(2015, 4, 18)
    status_cd 1
  end

  factory :job_3, class: Job do
		association :booking, factory: :booking_cancelled
		date Date.new(2015, 4, 19)
    status_cd 1
  end

  factory :job_4, class: Job do
		association :booking, factory: :booking_cancelled
		date Date.new(2015, 4, 20)
    status_cd 1
  end

  factory :job_5, class: Job do
		association :booking, factory: :booking_active_1
		date Date.new(2015, 4, 18)
    status_cd 1
		size 2
  end

  factory :job_6, class: Job do
		association :booking, factory: :booking_active_1
		date Date.new(2015, 4, 18)
		status_cd 1
  end

  factory :job_7, class: Job do
		association :booking, factory: :booking_active_1
		date Date.new(2015, 4, 18)
		status_cd 2
  end

  factory :job_8, class: Job do
		association :booking, factory: :booking_active_1
		date Date.new(2015, 4, 18)
		status_cd 3
  end

  factory :job_9, class: Job do
		association :booking, factory: :booking_active_1
		date Time.now + 5000
		status_cd 3
  end

  factory :job_10, class: Job do
		association :booking, factory: :booking_active_1
		date Time.now + 10000
		status_cd 3
	end

	factory :job_11, class: Job do
		association :booking, factory: :booking_active_1
		date Time.now + 15000
		status_cd 3
  end

  factory :job_12, class: Job do
		association :booking, factory: :booking_active_1
		date Date.new(2010, 10, 10)
		status_cd 3
  end

  factory :job_13, class: Job do
		association :booking, factory: :booking_active_1
		date (Date.today + 1.days)
		status_cd 3
  end

  factory :job_14, class: Job do
		association :booking, factory: :booking_active_1
		status_cd 5
  end

  factory :job_15, class: Job do
		association :booking, factory: :booking_active_1
		status_cd 6
		date (Date.today + 1.days)
  end
end
FactoryGirl.define do |job|
	factory :job_1, class: Job do
		association :booking, factory: :booking_cancelled
		date Date.new(2015, 4, 18)
  end

  factory :job_2, class: Job do
		association :booking, factory: :booking_active_1
		date Date.new(2015, 4, 18)
  end

  factory :job_3, class: Job do
		association :booking, factory: :booking_cancelled
		date Date.new(2015, 4, 19)
  end

  factory :job_4, class: Job do
		association :booking, factory: :booking_cancelled
		date Date.new(2015, 4, 20)
  end

  factory :job_5, class: Job do
		association :booking, factory: :booking_active_1
		date Date.new(2015, 4, 18)
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
end
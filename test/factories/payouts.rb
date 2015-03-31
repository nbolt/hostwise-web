FactoryGirl.define do |payouts|
  factory :payout_1, class: Payout do
    status_cd 0
    amount 1500
    association :job, factory: :job_1
  end

  factory :payout_2, class: Payout do
    status_cd 1
    amount 1700
    association :job, factory: :job_2
  end

  factory :payout_3, class: Payout do
    status_cd 0
    amount 1900
    association :job, factory: :job_3
  end

  factory :payout_4, class: Payout do
    status_cd 1
    amount 2100
    association :job, factory: :job_4
  end

  factory :payout_5, class: Payout do
    status_cd 2
    amount 3300
    association :job, factory: :job_5
  end

  factory :payout_6, class: Payout do
    status_cd 2
    amount 10100
    association :job, factory: :job_6
  end
end
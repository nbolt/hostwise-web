FactoryGirl.define do |user|
  factory :payment_1, class: Payment do
    status_cd 1
    primary true
  end
end
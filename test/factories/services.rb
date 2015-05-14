FactoryGirl.define do
  factory :cleaning, class: Service do
    name 'cleaning'
  end

  factory :linens, class: Service do
    name 'linens'
  end

  factory :toiletries, class: Service do
    name 'toiletries'
  end

  factory :pool, class: Service do
    name 'pool'
  end

  factory :patio, class: Service do
    name 'patio'
  end

  factory :windows, class: Service do
    name 'windows'
  end

  factory :preset, class: Service do
    name 'preset'
  end
end
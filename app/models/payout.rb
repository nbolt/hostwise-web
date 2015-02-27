class Payout < ActiveRecord::Base
  belongs_to :user
  belongs_to :job

  as_enum :status, pending: 0, completed: 1
end

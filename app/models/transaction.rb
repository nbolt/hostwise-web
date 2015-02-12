class Transaction < ActiveRecord::Base
  belongs_to :booking
  as_enum :status, successful: 0, failed: 1, pending: 2
end

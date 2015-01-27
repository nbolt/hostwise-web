class BackgroundCheck < ActiveRecord::Base
  belongs_to :user

  as_enum :status, canceled: 0, pending: 1, ready: 2, error: 3, partial: 4
end

class BackgroundCheck < ActiveRecord::Base
  belongs_to :user

  as_enum :status, pending: 0, clear: 1, consider: 2
end

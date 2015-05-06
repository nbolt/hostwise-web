class Bot < ActiveRecord::Base
  as_enum :status, deleted: 0, active: 1, contacted: 2
  as_enum :source, airbnb: 0, homeaway: 1
end

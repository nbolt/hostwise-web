class BotAccount < ActiveRecord::Base
  as_enum :status, deactivated: 0, active: 1, pending: 2
  as_enum :source, airbnb: 0, homeaway: 1, roomorama: 2, nineflats: 3, flipkey: 4
end

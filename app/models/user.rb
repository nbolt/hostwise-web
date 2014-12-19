class User < ActiveRecord::Base
  authenticates_with_sorcery!

  def name
    first_name + ' ' + last_name
  end
end

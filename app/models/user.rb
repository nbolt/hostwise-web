class User < ActiveRecord::Base
  authenticates_with_sorcery!

  has_many :properties
  has_many :payments, autosave: true, dependent: :destroy

  def name
    first_name + ' ' + last_name
  end
end

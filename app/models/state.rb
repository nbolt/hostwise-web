class State < ActiveRecord::Base
  has_many :counties, inverse_of: :state, dependent: :destroy
  validates :name,           presence: true, uniqueness: {case_sensitive: false}
  validates :abbr, presence: true, uniqueness: {case_sensitivie: false}
end
class ServiceZip < ActiveRecord::Base
  validates :zip, presence: true, uniqueness: {case_sensitive: false}
end

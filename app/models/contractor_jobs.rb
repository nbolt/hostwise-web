class ContractorJobs < ActiveRecord::Base
  belongs_to :booking
  belongs_to :user
end

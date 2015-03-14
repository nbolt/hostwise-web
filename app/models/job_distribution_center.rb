class JobDistributionCenter < ActiveRecord::Base
  belongs_to :job
  belongs_to :distribution_center
end

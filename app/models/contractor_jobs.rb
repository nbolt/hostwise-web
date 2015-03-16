class ContractorJobs < ActiveRecord::Base
  belongs_to :job
  belongs_to :user
  has_one :checklist, foreign_key: :contractor_job_id, dependent: :destroy

  after_create :create_checklist
end

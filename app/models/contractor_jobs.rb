class ContractorJobs < ActiveRecord::Base
  belongs_to :job
  belongs_to :user
  has_one :checklist, foreign_key: :contractor_job_id, dependent: :destroy

  after_save :create_check

  private

  def create_check
    create_checklist if primary && !checklist
  end
end

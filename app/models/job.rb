class Job < ActiveRecord::Base
  belongs_to :booking
  has_many :contractor_jobs, class_name: 'ContractorJobs'
  has_many :contractors, through: :contractor_jobs, source: :user

  as_enum :status, open: 0, scheduled: 1, complete: 2

  def self.open contractor
    Job.includes(:contractor_jobs).references(:contractor_jobs).where(status_cd: 0).where('contractor_jobs.user_id is null or contractor_jobs.user_id != ?', contractor.id)
  end

  def self.upcoming contractor
    Job.includes(:contractor_jobs).references(:contractor_jobs).where(status_cd: [0, 1]).where('contractor_jobs.user_id = ?', contractor.id)
  end

  def self.past contractor
    Job.includes(:contractor_jobs).references(:contractor_jobs).where(status_cd: 2).where('contractor_jobs.user_id = ?', contractor.id)
  end

  def size
    booking.services.count
  end
end

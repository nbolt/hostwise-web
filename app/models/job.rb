class Job < ActiveRecord::Base
  belongs_to :booking
  has_many :contractor_jobs, class_name: 'ContractorJobs'
  has_many :contractors, through: :contractor_jobs, source: :user

  as_enum :status, open: 0, scheduled: 1, in_progress: 2, completed: 3, past_due: 4

  scope :on_date, ->(date) { where('extract(year from date) = ? and extract(month from date) = ? and extract(day from date) = ?', date.year, date.month, date.day).includes(:booking).references(:booking) }
  scope :today, -> { on_date(Time.now.utc) }
  scope :distribution, -> { where(distribution: true) }
  scope :standard, -> { where(distribution: false) }
  scope :single, -> { where('size = 1') }
  scope :team, -> { where('size > 1') }

  def self.open contractor
    Job.where(status_cd: 0).where('(contractor_jobs.user_id is null or contractor_jobs.user_id != ?) and bookings.date >= ?', contractor.id, Date.today).order('bookings.date ASC').includes(:contractor_jobs, :booking).references(:contractor_jobs, :booking)
  end

  def self.upcoming contractor
    Job.where(status_cd: [0, 1]).where('contractor_jobs.user_id = ?', contractor.id).order('bookings.date ASC').includes(:contractor_jobs, :booking).references(:contractor_jobs, :booking)
  end

  def self.past contractor
    Job.where(status_cd: 3).where('contractor_jobs.user_id = ?', contractor.id).order('bookings.date ASC').includes(:contractor_jobs, :booking).references(:contractor_jobs, :booking)
  end

  def start!
    in_progress!
    save
    TwilioJob.perform_later("+1#{self.booking.property.user.phone_number}", "Porter arrived at #{self.booking.property.short_address}") if self.booking.property.user.settings(:porter_arrived).sms
  end

  def complete!
    completed!
    booking.charge!
    save
  end

  def handle_distribution_job user
    jobs = user.jobs.on_date(booking.date)
    standard_jobs = jobs.standard
    distribution_job = jobs.distribution[0]
    team_job = jobs.team[0]
    single_jobs = standard_jobs.single
    supplies = {king_beds:0,queen_beds:0,full_beds:0,twin_beds:0,toiletries:0}

    if single_jobs[0]
      distribution_job = user.jobs.create(distribution: true, status_cd: 1, priority: 0, booking_id: booking.id) unless distribution_job
      single_jobs.each do |job|
        supplies[:king_beds] += job.booking.property.king_beds
        supplies[:queen_beds] += job.booking.property.queen_beds
        supplies[:full_beds] += job.booking.property.full_beds
        supplies[:twin_beds] += job.booking.property.twin_beds
        supplies[:toiletries] += 1 if job.booking.services.index Service.where(name: 'toiletries')[0]
      end
    end

    if team_job && team_job.contractors.count == 1
      distribution_job = user.jobs.create(distribution: true, status_cd: 1, priority: 0, booking_id: booking.id) unless distribution_job
      supplies[:king_beds] += team_job.booking.property.king_beds
      supplies[:queen_beds] += team_job.booking.property.queen_beds
      supplies[:full_beds] += team_job.booking.property.full_beds
      supplies[:twin_beds] += team_job.booking.property.twin_beds
      supplies[:toiletries] += 1 if job.booking.services.index Service.where(name: 'toiletries')[0]
    end

    if standard_jobs.empty?
      distribution_job.destroy if distribution_job
    end

    if distribution_job
      supplies.each do |k,v|
        distribution_job[k] = v
      end
      distribution_job.save
    end
  end

  def self.set_priorities jobs
    team_job = jobs.team[0]
    team_job.update_attribute :priority, 1 if team_job
    num = jobs.map(&:priority).max
    jobs.where(priority:0).each_with_index do |job, index|
      job.update_attribute :priority, index + num + 1
    end
  end
end

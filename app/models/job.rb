class Job < ActiveRecord::Base
  include PgSearch
  pg_search_scope :search, associated_against: {booking: [:property_id]}

  belongs_to :booking
  has_many :contractor_jobs, class_name: 'ContractorJobs', dependent: :destroy
  has_many :contractors, through: :contractor_jobs, source: :user
  has_many :payouts

  as_enum :status, open: 0, scheduled: 1, in_progress: 2, completed: 3, past_due: 4
  as_enum :state, normal: 0, vip: 1, hidden: 2

  scope :first_jobs, -> { where('contractor_jobs.priority = 1').includes(:contractor_jobs).references(:contractor_jobs) }
  scope :trainers, -> { where('contractor_jobs.user_id in (?)', User.trainers.map(&:id)).includes(:contractors).references(:contractors) }
  scope :future, -> { where('date >= ?', Time.now) }
  scope :on_date, -> (date) { where('extract(year from date) = ? and extract(month from date) = ? and extract(day from date) = ?', date.year, date.month, date.day) }
  scope :today, -> { on_date(Time.now) }
  scope :distribution, -> { where(distribution: true) }
  scope :standard, -> { where(distribution: false) }
  scope :single, -> { where('size = 1') }
  scope :team, -> { where('size > 1') }
  scope :ordered, -> (user) { where('contractor_jobs.user_id = ?', user.id).order('contractor_jobs.priority').includes(:contractor_jobs).references(:contractor_jobs) }
  scope :open, -> (contractor) { standard.where(status_cd: 0).where('(contractor_jobs.user_id is null or contractor_jobs.user_id != ?) and date >= ?', contractor.id, Date.today).order('date ASC').includes(:contractor_jobs).references(:contractor_jobs) }
  scope :upcoming, -> (contractor) { standard.where(status_cd: [0, 1]).where('contractor_jobs.user_id = ?', contractor.id).order('date ASC').includes(:contractor_jobs).references(:contractor_jobs) }
  scope :past, -> (contractor) { standard.where(status_cd: 3).where('contractor_jobs.user_id = ?', contractor.id).order('date ASC').includes(:contractor_jobs).references(:contractor_jobs) }

  attr_accessor :current_user

  def priority contractor
    ContractorJobs.where(user_id: contractor.id, job_id: self.id)[0].priority
  end

  def next_job contractor
    contractor.jobs.on_date(date).where('contractor_jobs.priority > ?', priority(contractor)).order('contractor_jobs.priority').includes(:contractor_jobs).references(:contractor_jobs)[0]
  end

  def previous_job contractor
    contractor.jobs.on_date(date).where('contractor_jobs.priority < ?', priority(contractor)).order('contractor_jobs.priority').includes(:contractor_jobs).references(:contractor_jobs)[-1]
  end

  def payout contractor=nil
    if booking
      payout_multiplier = state == :vip ? 0.75 : 0.7
      if booking.cancelled?
        (booking.cost / size).round 2
      else
        contractor ||= current_user
        payout = 0
        pricing = Booking.cost booking.property, booking.services, booking.first_booking_discount, booking.late_next_day, booking.late_same_day, booking.no_access_fee
        payout += (pricing[:cleaning] * payout_multiplier).round(2) if pricing[:cleaning]
        payout += (PRICING['preset'][booking.property.beds] * payout_multiplier).round(2) if pricing[:preset]
        payout += PRICING['pool_payout'] if pricing[:pool]
        payout += PRICING['patio_payout']  if pricing[:patio] unless pricing[:pool]
        payout += PRICING['windows_payout']  if pricing[:windows] unless pricing[:pool]
        payout += PRICING['no_access_fee_payout'] if booking.no_access_fee
        if size > 1
          if contractor && !contractor.admin? # requesting pricing for specific contractor (job detail page)
            if ContractorJobs.where(job_id: self.id, user_id: contractor.id)[0].primary
              payout *= 0.55
            else
              payout *= 0.45
            end
          else
            if contractor && contractor.admin? # average pricing for viewing job detail as admin
              payout /= size
            else
              if contractors.empty? # pricing for open jobs
                payout *= 0.55
              else
                payout *= 0.45
              end
            end
          end
        elsif training && contractor
          if contractor.status == :trainee
            payout *= 0.45
          else
            payout *= 0.55
          end
        end
        payout.round 2
      end
    end
  end

  def payout_integer
    payout.to_s.split('.')[0].to_i if booking
  end

  def payout_fractional
    payout.to_s.split('.')[1].to_i if booking
  end

  def start!
    in_progress!
    save
    TwilioJob.perform_later("+1#{self.booking.property.user.phone_number}", "HostWise arrived at #{self.booking.property.short_address}") if self.booking.property.user.settings(:porter_arrived).sms
  end

  def complete!
    completed!
    if booking
      contractors.each do |contractor|
        contractor.payouts.create(job_id: self.id, amount: payout(contractor) * 100)
      end
      booking.update_attribute :status_cd, 3
      booking.charge!
    end
    save
    contractors.each do |contractor|
      job = self.next_job(contractor)
      TwilioJob.perform_later("+1#{job.booking.property.user.phone_number}", 'HostWise is en route to service your property') if job.present? && job.booking.property.user.settings(:porter_en_route).sms
    end
  end

  def handle_distribution_job user
    jobs = user.jobs.on_date(booking.date)
    standard_jobs = jobs.standard
    distribution_job = jobs.distribution[0]
    team_job = jobs.team[0]
    single_jobs = standard_jobs.single
    supplies = {king_beds:0,queen_beds:0,full_beds:0,twin_beds:0,toiletries:0}

    if single_jobs[0]
      distribution_job = user.jobs.create(distribution: true, status_cd: 1, date: booking.date) unless distribution_job
      single_jobs.each do |job|
        if job.booking.services.index Service.where(name: 'linens')[0]
          supplies[:king_beds] += job.booking.property.king_beds
          supplies[:queen_beds] += job.booking.property.queen_beds
          supplies[:full_beds] += job.booking.property.full_beds
          supplies[:twin_beds] += job.booking.property.twin_beds
        end
        job.booking.property.beds.times { supplies[:toiletries] += 1 } if job.booking.services.index Service.where(name: 'toiletries')[0]
      end
    end

    if team_job && team_job.contractors.count == 1
      distribution_job = user.jobs.create(distribution: true, status_cd: 1, date: booking.date) unless distribution_job
      if team_job.booking.services.index Service.where(name: 'linens')[0]
        supplies[:king_beds] += team_job.booking.property.king_beds
        supplies[:queen_beds] += team_job.booking.property.queen_beds
        supplies[:full_beds] += team_job.booking.property.full_beds
        supplies[:twin_beds] += team_job.booking.property.twin_beds
      end
      team_job.booking.property.beds.times { supplies[:toiletries] += 1 } if team_job.booking.services.index Service.where(name: 'toiletries')[0]
    end

    if distribution_job
      supplies.each do |k,v|
        distribution_job[k] = v
      end
      distribution_job.save
    end

    if standard_jobs.empty?
      distribution_job.destroy if distribution_job
    end
  end

  def self.set_priorities jobs, contractor
    team_job = jobs.team[0]
    if team_job
      contractor_job = contractor.contractor_jobs.where(job_id: team_job.id)[0]
      contractor_job.update_attribute :priority, 1
      jobs.each do |job|
        contractor_job = contractor.contractor_jobs.where(job_id: job.id)[0]
        contractor_job.update_attribute :priority, 0 if contractor_job.priority == 1
      end
    end
    num = jobs.map{|job| contractor.contractor_jobs.where(job_id: job.id)[0].priority}.max

    unprioritized_jobs = jobs.select do |job|
      contractor_job = contractor.contractor_jobs.where(job_id: job.id)[0]
      contractor_job.priority == 0
    end

    unprioritized_jobs.each_with_index do |job, index|
      contractor_job = contractor.contractor_jobs.where(job_id: job.id)[0]
      contractor_job.update_attribute :priority, num + index + 1
    end
  end
end

class Job < ActiveRecord::Base
  include PgSearch
  pg_search_scope :search, associated_against: {booking: [:property_id]}

  belongs_to :booking

  has_one :distribution_center, through: :job_distribution_center
  has_one :job_distribution_center, dependent: :destroy

  has_many :contractor_jobs, class_name: 'ContractorJobs', dependent: :destroy
  has_many :contractors, through: :contractor_jobs, source: :user
  has_many :payouts

  as_enum :status, open: 0, scheduled: 1, in_progress: 2, completed: 3, past_due: 4, cant_access: 5
  as_enum :state, normal: 0, vip: 1, hidden: 2
  as_enum :occasion, pickup: 0, dropoff: 1

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
  scope :open, -> (contractor) { standard.days(contractor).where(status_cd: 0).where('(contractor_jobs.user_id is null or contractor_jobs.user_id != ?) and date >= ?', contractor.id, Date.today).order('date ASC').includes(:contractor_jobs).references(:contractor_jobs) }
  scope :upcoming, -> (contractor) { standard.where(status_cd: [0, 1]).where('contractor_jobs.user_id = ?', contractor.id).order('date ASC').includes(:contractor_jobs).references(:contractor_jobs) }
  scope :past, -> (contractor) { standard.where(status_cd: 3).where('contractor_jobs.user_id = ?', contractor.id).order('date ASC').includes(:contractor_jobs).references(:contractor_jobs) }
  scope :days, -> (contractor) { sun(contractor).mon(contractor).tue(contractor).wed(contractor).thurs(contractor).fri(contractor).sat(contractor) }
  scope :sun, -> (contractor) { where("extract(dow from date) != ? OR #{contractor.availability.sun} = ?", 0, true).includes(contractors: [:availability]).references(:availability) }
  scope :mon, -> (contractor) { where("extract(dow from date) != ? OR #{contractor.availability.mon} = ?", 1, true).includes(contractors: [:availability]).references(:availability) }
  scope :tue, -> (contractor) { where("extract(dow from date) != ? OR #{contractor.availability.tues} = ?", 2, true).includes(contractors: [:availability]).references(:availability) }
  scope :wed, -> (contractor) { where("extract(dow from date) != ? OR #{contractor.availability.wed} = ?", 3, true).includes(contractors: [:availability]).references(:availability) }
  scope :thurs, -> (contractor) { where("extract(dow from date) != ? OR #{contractor.availability.thurs} = ?", 4, true).includes(contractors: [:availability]).references(:availability) }
  scope :fri, -> (contractor) { where("extract(dow from date) != ? OR #{contractor.availability.fri} = ?", 5, true).includes(contractors: [:availability]).references(:availability) }
  scope :sat, -> (contractor) { where("extract(dow from date) != ? OR #{contractor.availability.sat} = ?", 6, true).includes(contractors: [:availability]).references(:availability) }
  scope :pickup,  -> { where(occasion_cd: 0) }
  scope :dropoff, -> { where(occasion_cd: 1) }

  attr_accessor :current_user, :distance

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
          if contractor.contractor_profile.position == :trainee
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

  def man_hours
    MAN_HRS[booking.property.property_type.to_s][booking.property.bedrooms][booking.property.bathrooms] / size if booking
  end

  def staging
    booking.services.index Service.where(name: 'preset')[0] if booking
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

  def handle_distribution_jobs user
    jobs = user.jobs.on_date(date)
    standard_jobs = jobs.standard
    distribution_job = jobs.distribution.pickup.first
    dropoff_job = jobs.distribution.dropoff.first
    team_job = jobs.team[0]
    single_jobs = standard_jobs.single
    supplies = {king_beds:0,queen_beds:0,full_beds:0,twin_beds:0,toiletries:0}

    if standard_jobs.empty?
      jobs.distribution.destroy_all
    else
      if single_jobs[0]
        distribution_job = user.jobs.create(distribution: true, status_cd: 1, date: date, occasion_cd: 0) unless distribution_job
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
        distribution_job = user.jobs.create(distribution: true, status_cd: 1, date: date, occasion_cd: 0) unless distribution_job
        if team_job.booking.services.index Service.where(name: 'linens')[0]
          supplies[:king_beds] += team_job.booking.property.king_beds
          supplies[:queen_beds] += team_job.booking.property.queen_beds
          supplies[:full_beds] += team_job.booking.property.full_beds
          supplies[:twin_beds] += team_job.booking.property.twin_beds
        end
        team_job.booking.property.beds.times { supplies[:toiletries] += 1 } if team_job.booking.services.index Service.where(name: 'toiletries')[0]
      end

      if distribution_job
        dropoff_job = user.jobs.create(distribution: true, status_cd: 1, date: date, occasion_cd: 1) unless dropoff_job
        supplies.each do |k,v|
          distribution_job[k] = v
          dropoff_job[k]      = v
        end
        distribution_job.save
        dropoff_job.save
      end
    end
  end

  def self.set_priorities jobs, contractor
    standard_jobs = jobs.standard
    paths = []
    (DistributionCenter.all.map{|dc| [dc, dc]} + DistributionCenter.all.to_a.permutation(2).to_a).each do |dc_permutation|
      standard_jobs.to_a.permutation(standard_jobs.length).to_a.each do |jobs_permutation|
        jobs_permutation = jobs_permutation - [jobs.team[0]]
        properties = jobs_permutation.map {|job| job.booking.property}

        pre_path = [contractor.contractor_profile]
        pre_path.append dc_permutation[0] if jobs.distribution[0]
        pre_path.append jobs.team[0].booking.property if jobs.team[0]

        post_path = [contractor.contractor_profile]
        post_path.unshift dc_permutation[1] if jobs.distribution[0]

        path = pre_path + properties + post_path
        distance = 0
        (path.length - 1).times do |i|
          haversine = Haversine.distance(path[i].lat, path[i].lng, path[i+1].lat, path[i+1].lng)
          distance += haversine if haversine
        end

        pre_path[-1] = jobs.team[0] if pre_path[-1].class == Property
        paths.push([distance, pre_path[1..-1] + jobs_permutation + post_path[0..-2]])
      end
    end
    chosen_path = paths.sort_by {|path| path[0]}[0]

    chosen_path[1].each_with_index do |location, index|
      if location.class == DistributionCenter
        if index == 0
          ContractorJobs.where(job_id: jobs.distribution.pickup[0].id, user_id: contractor.id)[0].update_attribute :priority, index
        else
          ContractorJobs.where(job_id: jobs.distribution.dropoff[0].id, user_id: contractor.id)[0].update_attribute :priority, index
        end
      else
        ContractorJobs.where(job_id: location.id, user_id: contractor.id)[0].update_attribute :priority, index
      end
    end
  end
end

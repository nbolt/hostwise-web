class Job < ActiveRecord::Base
  include PgSearch
  pg_search_scope :search, against: [:id], associated_against: {booking: [:property_id]}

  belongs_to :booking

  has_one :distribution_center, through: :job_distribution_center
  has_one :job_distribution_center, dependent: :destroy

  has_many :contractor_jobs, class_name: 'ContractorJobs', dependent: :destroy
  has_many :contractors, through: :contractor_jobs, source: :user
  has_many :payouts

  as_enum :status, open: 0, scheduled: 1, in_progress: 2, completed: 3, past_due: 4, cant_access: 5, cancelled: 6
  as_enum :state, normal: 0, vip: 1, hidden: 2
  as_enum :occasion, pickup: 0, dropoff: 1

  scope :first_jobs, -> { where('contractor_jobs.priority = 1').includes(:contractor_jobs).references(:contractor_jobs) }
  scope :trainers, -> { where('contractor_jobs.user_id in (?)', User.trainers.map(&:id)).includes(:contractors).references(:contractors) }
  scope :future, -> (zone=nil) {
    timezone = Timezone::Zone.new :zone => zone if zone
    now = zone && timezone.time(Time.now) || Time.now
    if now.hour < 14
      where('date >= ?', now)
    else
      where('date > ?', now)
    end
  }
  scope :future_from_today, -> (zone=nil) {
    timezone = Timezone::Zone.new :zone => zone if zone
    now = zone && timezone.time(Time.now) || Time.now
    where('date >= ?', now)
  }
  scope :on_date, -> (date) {
    date = date.to_date if date.class == Time
    where(date: date)
  }
  scope :on_month, -> (month) { where('extract(month from jobs.date) = ?', month) }
  scope :in_week, -> (week, date) { where('extract(year from jobs.date) = ? and extract(month from jobs.date) = ? and extract(day from jobs.date) in (?)', date.year, date.month, week) }
  scope :today, -> { on_date(Time.now) }
  scope :distribution, -> { where(distribution: true) }
  scope :scheduled, -> { where(status_cd: 1) }
  scope :not_complete, -> { where(status_cd: [0,1,2]) }
  scope :complete, -> { where(status_cd: 3) }
  scope :cancelled, -> { where(status_cd: 6) }
  scope :training, -> { where(training: true) }
  scope :not_training, -> { where(training: false) }
  scope :standard, -> { where(distribution: false) }
  scope :single, -> { where('size = 1') }
  scope :team, -> { where('size > 1') }
  scope :ordered, -> (user) { where('contractor_jobs.user_id = ?', user.id).order('contractor_jobs.priority').includes(:contractor_jobs).references(:contractor_jobs) }
  scope :open, -> (contractor) {
    states = contractor.contractor_profile.position == :trainer ? [0,1] : 0
    standard.days(contractor).where(state_cd: states, status_cd: 0)
    .where('(contractor_jobs.user_id is null or contractor_jobs.user_id != ?) and date >= ?', contractor.id, Date.today)
    .order('date ASC').includes(:contractor_jobs).references(:contractor_jobs)
  }
  scope :upcoming, -> (contractor) { standard.where(status_cd: [0, 1]).where('contractor_jobs.user_id = ?', contractor.id).order('date ASC').includes(:contractor_jobs).references(:contractor_jobs) }
  scope :past, -> (contractor) { standard.where(status_cd: 3).where('contractor_jobs.user_id = ?', contractor.id).order('date ASC').includes(:contractor_jobs).references(:contractor_jobs) }

  scope :sun, -> (contractor) { where("extract(dow from date) != ? OR #{contractor.availability.sun} = ?", 0, true).includes(contractors: [:availability]).references(:availability) }
  scope :mon, -> (contractor) { where("extract(dow from date) != ? OR #{contractor.availability.mon} = ?", 1, true).includes(contractors: [:availability]).references(:availability) }
  scope :tue, -> (contractor) { where("extract(dow from date) != ? OR #{contractor.availability.tues} = ?", 2, true).includes(contractors: [:availability]).references(:availability) }
  scope :wed, -> (contractor) { where("extract(dow from date) != ? OR #{contractor.availability.wed} = ?", 3, true).includes(contractors: [:availability]).references(:availability) }
  scope :thurs, -> (contractor) { where("extract(dow from date) != ? OR #{contractor.availability.thurs} = ?", 4, true).includes(contractors: [:availability]).references(:availability) }
  scope :fri, -> (contractor) { where("extract(dow from date) != ? OR #{contractor.availability.fri} = ?", 5, true).includes(contractors: [:availability]).references(:availability) }
  scope :sat, -> (contractor) { where("extract(dow from date) != ? OR #{contractor.availability.sat} = ?", 6, true).includes(contractors: [:availability]).references(:availability) }
  scope :days, -> (contractor) { sun(contractor).mon(contractor).tue(contractor).wed(contractor).thurs(contractor).fri(contractor).sat(contractor) }

  scope :pickup,  -> { where(occasion_cd: 0) }
  scope :dropoff, -> { where(occasion_cd: 1) }

  before_save :assign_man_hours

  attr_accessor :current_user, :distance

  def self.revenue_by_months date
    revenue = []
    4.times do |i|
      month = (date - i.months).month
      jobs = Job.on_month(month).where('status_cd > 2')
      revenue.unshift({ month: month, revenue: jobs.reduce(0) {|acc, job| acc + (job.chain(:booking, :cost) || 0)} })
    end
    revenue.select {|r| r[:revenue] > 0}
  end

  def self.serviced_by_months date
    serviced = []
    4.times do |i|
      month = (date - i.months).month
      jobs = Job.on_month(month).where('status_cd > 2')
      serviced.unshift({ month: month, serviced: jobs.count })
    end
    serviced.select {|r| r[:serviced] > 0}
  end

  def self.properties_by_months date
    properties = []
    4.times do |i|
      month = (date - i.months).month
      jobs = Job.on_month(month).where('status_cd > 2').to_a.uniq { |job| job.chain(:booking, :property, :id) }
      properties.unshift({ month: month, properties: jobs.count })
    end
    properties.select {|r| r[:properties] > 0}
  end

  def self.hosts_by_months date
    hosts = []
    4.times do |i|
      month = (date - i.months).month
      jobs = Job.on_month(month).where('status_cd > 2').to_a.uniq { |job| job.chain(:booking, :user, :id) }
      hosts.unshift({ month: month, hosts: jobs.count })
    end
    hosts.select {|r| r[:hosts] > 0}
  end

  def self.jobs_in_week jobs, week, date
    jobs.select {|job| job.date.year == date.year && job.date.month == date.month && week.index(job.date.day)}
  end

  def king_bed_count
    booking.property.king_bed_count + booking.extra_king_sets if booking
  end

  def twin_bed_count
    booking.property.twin_beds + booking.extra_twin_sets if booking
  end

  def toiletry_count
    booking.property.bathrooms + booking.extra_toiletry_sets if booking
  end

  def contractor_names
    contractors.map(&:name).join ', '
  end

  def priority contractor=nil
    contractor ||= current_user
    ContractorJobs.where(user_id: contractor.id, job_id: self.id)[0].priority if contractor
  end

  def tomorrow? date
    if self.date == date + 1.day
      true
    else
      false
    end
  end

  def next_job contractor=nil
    contractor ||= current_user
    contractor.jobs.on_date(date).where('status_cd = 1 AND contractor_jobs.priority > ?', priority(contractor)).order('contractor_jobs.priority').includes(:contractor_jobs).references(:contractor_jobs)[0]
  end

  def prev_job contractor=nil
    contractor ||= current_user
    contractor.jobs.on_date(date).where('contractor_jobs.priority < ?', priority(contractor)).order('contractor_jobs.priority').includes(:contractor_jobs).references(:contractor_jobs)[-1]
  end

  def payout contractor=nil
    if booking
      if booking.cancelled? || booking.couldnt_access?
        ((booking.original_cost / size) * 0.8).round 2
      else
        contractor ||= current_user
        payout_multiplier = state == :vip ? 0.75 : 0.7
        if training
          payout_multiplier = 0.8 if payout_multiplier == 0.7
          payout_multiplier = 0.85 if payout_multiplier == 0.75
        end
        payout = 0
        pricing = booking.pricing_hash
        payout += (pricing[:cleaning] * payout_multiplier).round(2) if pricing[:cleaning] > 0
        payout += (PRICING['preset'][booking.property.beds] * payout_multiplier).round(2) if pricing[:preset] > 0
        payout += PRICING['pool_payout'] if pricing[:pool] > 0
        payout += PRICING['patio_payout']  if pricing[:patio] > 0
        payout += PRICING['windows_payout']  if pricing[:windows] > 0
        payout += PRICING['no_access_fee_payout'] if pricing[:no_access_fee] > 0

        if contractor.chain(:contractor_profile, :position) == :trainee
          payout = 20
        elsif size > 1
          even_payout = (payout / size).round 2
          primary_payout = (even_payout + (even_payout * 0.1)).round 2
          secondary_payout = (even_payout - ((primary_payout - even_payout) / (size-1))).round 2
          contractor_job = contractor && ContractorJobs.where(job_id: self.id, user_id: contractor.id)[0]
          if contractor_job && !contractor.admin? # requesting pricing for specific contractor (job detail page)
            if contractor_job.primary
              payout = primary_payout
            else
              payout = secondary_payout
            end
          else
            if contractor && contractor.admin? # average pricing for viewing job detail as admin
              payout /= size
            else
              if contractors.empty? # pricing for open jobs
                payout = primary_payout
              else
                payout = secondary_payout
              end
            end
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

  def primary_contractor
    ContractorJobs.where(job_id: self.id, primary: true)[0].then(:user)
  end

  def primary contractor=nil
    contractor ||= current_user
    ContractorJobs.where(job_id: self.id, user_id: contractor.id)[0].primary if contractor
  end

  def checklist
    ContractorJobs.where(job_id: self.id, primary: true)[0].then(:checklist)
  end

  def minimum_job_size
    if booking
      if (booking.property.bedrooms == 3 && booking.property.bathrooms >= 3) || booking.property.bedrooms > 3 then 2 else 1 end
    end
  end

  def contractor_hours contractor=nil
    contractor ||= current_user
    contractor.man_hours date
  end

  def first_job_of_day contractor=nil
    contractor ||= current_user
    if contractor
      if contractor.jobs.on_date(date)[0] then false else true end
    end
  end

  def is_last_job_of_day contractor=nil
    contractor ||= current_user
    if contractor
      jobs_on_date = contractor.jobs.standard.on_date(date).sort_by {|job| job.priority contractor}
      self == jobs_on_date[-1]
    end
  end

  def index_in_day contractor=nil
    contractor ||= current_user
    if contractor
      jobs_on_date = contractor.jobs.standard.on_date(date).sort_by {|job| job.priority contractor}
      jobs_on_date.index self
    end
  end

  def previous_team_job contractor=nil
    contractor ||= current_user
    if contractor
      if contractor.jobs.on_date(date).team[0] then true else false end
    end
  end

  def staging
    booking.services.select {|s| s.name == 'preset' }.count > 0 if booking
  end

  def has_linens?
    booking.services.select {|s| s.name == 'linens' }.count > 0
  end

  def has_toiletries?
    booking.services.select {|s| s.name == 'toiletries' }.count > 0
  end

  def complete?
    status_cd > 2
  end

  def in_progress?
    status_cd == 2
  end

  def not_complete?
    status_cd < 3
  end

  def formatted_date
    date.strftime '%m/%d/%Y'
  end

  def cant_access_seconds_left
    if cant_access
      num = (CANT_ACCESS_MINUTES * 60) - (Time.now - cant_access).round
      if num < 0 then 0 else num end
    end
  end

  def inventory_count!
    standard_jobs = primary_contractor.jobs.standard.on_date(date)

    ['king_sheets', 'twin_sheets', 'pillow_count', 'bath_towels', 'hand_towels', 'face_towels', 'bath_mats'].each do |type|
      update_attribute type.to_sym, standard_jobs.reduce(0) do |acc, job|
        if job.checklist
          checklist_id = job.checklist.id
          settings = RailsSettings::SettingObject.where(var: 'inventory_count', target_id: checklist_id)[0]
          if settings.chain(:value, type)
            acc + settings.chain(:value, type)
          else
            acc
          end
        end
      end
    end
  end

  def complete!
    completed!
    inventory_count! if occasion == :dropoff
    pay_contractors!
    booking.update_attribute :status_cd, 3 if booking
    save
  end

  def pay_contractors!
    contractors.each do |contractor|
      unless Payout.where(job_id: self.id, user_id: contractor.id)[0] || !payout(contractor)
        contractor.payouts.create(job_id: self.id, amount: payout(contractor) * 100)
      end
    end
  end

  def handle_distribution_jobs user
    jobs = user.jobs.on_date(date)
    standard_jobs = jobs.standard
    distribution_job = jobs.distribution.pickup.first
    dropoff_job = jobs.distribution.dropoff.first
    team_job = jobs.team[0]
    single_jobs = standard_jobs.single
    supplies = {king_beds:0,twin_beds:0,toiletries:0}
    not_complete = false

    if standard_jobs.empty?
      jobs.distribution.destroy_all
    else
      if single_jobs[0]
        distribution_job = user.jobs.create(distribution: true, status_cd: 1, date: date, occasion_cd: 0) unless distribution_job
        single_jobs.each do |job|
          not_complete = true if job.not_complete?
          if job.has_linens?
            supplies[:king_beds] += job.booking.property.king_beds
            supplies[:king_beds] += job.booking.property.queen_beds
            supplies[:king_beds] += job.booking.property.full_beds
            supplies[:king_beds] += job.booking.extra_king_sets
            supplies[:twin_beds] += job.booking.property.twin_beds
            supplies[:twin_beds] += job.booking.extra_twin_sets
          end
          if job.has_toiletries?
            job.booking.property.bathrooms.times { supplies[:toiletries] += 1 }
            supplies[:toiletries] += job.booking.extra_toiletry_sets
          end
        end
      end

      if team_job && team_job.contractors.count == 1
        distribution_job = user.jobs.create(distribution: true, status_cd: 1, date: date, occasion_cd: 0) unless distribution_job
        not_complete = true if team_job.not_complete?
        if team_job.has_linens?
          supplies[:king_beds] += team_job.booking.property.king_beds
          supplies[:king_beds] += team_job.booking.property.queen_beds
          supplies[:king_beds] += team_job.booking.property.full_beds
          supplies[:king_beds] += team_job.booking.extra_king_sets
          supplies[:twin_beds] += team_job.booking.property.twin_beds
          supplies[:twin_beds] += team_job.booking.extra_twin_sets
        end
        if team_job.has_toiletries?
          team_job.booking.property.bathrooms.times { supplies[:toiletries] += 1 }
          supplies[:toiletries] += team_job.booking.extra_toiletry_sets
        end
      end

      if distribution_job
        dropoff_job = user.jobs.create(distribution: true, status_cd: 1, date: date, occasion_cd: 1) unless dropoff_job
        supplies.each do |k,v|
          distribution_job[k] = v
          dropoff_job[k]      = v
        end
        if not_complete
          distribution_job.status_cd = 1
          dropoff_job.status_cd = 1
        end
        distribution_job.contractor_jobs[0].update_attribute :primary, true
        dropoff_job.contractor_jobs[0].update_attribute :primary, true
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
        team_job = standard_jobs.find {|job| job.contractors.count > 1}
        jobs_permutation = jobs_permutation - [team_job]
        properties = jobs_permutation.map {|job| job.booking.property}

        pre_path = [contractor.contractor_profile]
        pre_path.append dc_permutation[0] if jobs.distribution[0]
        pre_path.append team_job.booking.property if team_job

        post_path = [contractor.contractor_profile]
        post_path.unshift dc_permutation[1] if jobs.distribution[0]

        path = pre_path + properties + post_path
        distance = 0
        (path.length - 1).times {|i| distance += Haversine.distance(path[i].lat, path[i].lng, path[i+1].lat, path[i+1].lng)}

        pre_path[-1] = team_job if pre_path[-1].class == Property
        paths.push([distance, pre_path[1..-1] + jobs_permutation + post_path[0..-2]])
      end
    end
    chosen_path = paths.sort_by {|path| path[0]}[0]

    chosen_path[1].each_with_index do |location, index|
      if location.class == DistributionCenter
        if index == 0
          jobs.distribution.pickup[0].distribution_center = location
          ContractorJobs.where(job_id: jobs.distribution.pickup[0].id, user_id: contractor.id)[0].update_attribute :priority, index
        else
          jobs.distribution.dropoff[0].distribution_center = location
          ContractorJobs.where(job_id: jobs.distribution.dropoff[0].id, user_id: contractor.id)[0].update_attribute :priority, index
        end
      else
        ContractorJobs.where(job_id: location.id, user_id: contractor.id)[0].update_attribute :priority, index
      end
    end
  end

  private

  def assign_man_hours
    self.man_hours = MAN_HRS[booking.property.property_type.to_s][booking.property.bedrooms][booking.property.bathrooms] / size if booking
  end
end

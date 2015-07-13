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
      where('jobs.date >= ?', now)
    else
      where('jobs.date > ?', now)
    end
  }
  scope :future_from_today, -> (zone=nil) {
    timezone = Timezone::Zone.new :zone => zone if zone
    now = zone && timezone.time(Time.now) || Time.now
    where('jobs.date >= ?', now)
  }
  scope :on_date, -> (date) {
    date = date.to_date if date.class == Time
    where(date: date)
  }
  scope :within_market, -> (market) { where('markets.id = ?', market.id).references(:markets).includes(booking: {property: {zip_code: :market}}) || where(id:nil) }
  scope :on_month, -> (date) { where('extract(month from jobs.date) = ? and extract(year from jobs.date) = ?', date.month, date.year) }
  scope :on_year, -> (date) { where('extract(year from jobs.date) = ?', date.year) }
  scope :in_week, -> (week, date) { where('extract(year from jobs.date) = ? and extract(month from jobs.date) = ? and extract(day from jobs.date) in (?)', date.year, date.month, week) }
  scope :today, -> { on_date(Date.today) }
  scope :distribution, -> { where(distribution: true) }
  scope :scheduled, -> { where(status_cd: 1) }
  scope :not_complete, -> { where(status_cd: [0,1,2]) }
  scope :complete, -> { where(status_cd: 3) }
  scope :cancelled, -> { where(status_cd: 6) }
  scope :training, -> { where(training: true) }
  scope :not_training, -> { where(training: false) }
  scope :standard, -> { where(distribution: false) }
  scope :single, -> { where('jobs.size = 1') }
  scope :team, -> { where('jobs.size > 1') }
  scope :timed, -> { where('(bookings.timeslot is not null and jobs.size != 1) or bookings.timeslot_type_cd = 1 or jobs.admin_set = ?', true).includes(booking: [:job]).references(:bookings, :jobs) }
  scope :untimed, -> { where('(bookings.timeslot is null or jobs.size = 1) and bookings.timeslot_type_cd = 0 and jobs.admin_set = ?', false).includes(booking: [:job]).references(:bookings, :jobs) }
  scope :ordered, -> (user) { where('contractor_jobs.user_id = ?', user.id).order('contractor_jobs.priority').includes(:contractor_jobs).references(:contractor_jobs) }
  scope :open, -> (contractor) {
    states = contractor.contractor_profile.position_cd > 2 ? [0,1] : 0
    standard.days(contractor).within_market(contractor.contractor_profile.market).where(state_cd: states, status_cd: 0)
    .where('(contractor_jobs.user_id is null or contractor_jobs.user_id != ?) and jobs.date >= ? and jobs.date <= ?', contractor.id, Date.today, Date.today + 2.weeks)
    .order('jobs.date ASC').includes(:contractor_jobs).references(:contractor_jobs)
  }
  scope :upcoming, -> (contractor) { standard.where(status_cd: [0, 1]).where('contractor_jobs.user_id = ?', contractor.id).order('date ASC').includes(:contractor_jobs).references(:contractor_jobs) }
  scope :past, -> (contractor) { standard.where(status_cd: 3).where('contractor_jobs.user_id = ?', contractor.id).order('date ASC').includes(:contractor_jobs).references(:contractor_jobs) }

  scope :sun, -> (contractor) { where("extract(dow from jobs.date) != ? OR #{contractor.availability.sun} = ?", 0, true).includes(contractors: [:availability]).references(:availability) }
  scope :mon, -> (contractor) { where("extract(dow from jobs.date) != ? OR #{contractor.availability.mon} = ?", 1, true).includes(contractors: [:availability]).references(:availability) }
  scope :tue, -> (contractor) { where("extract(dow from jobs.date) != ? OR #{contractor.availability.tues} = ?", 2, true).includes(contractors: [:availability]).references(:availability) }
  scope :wed, -> (contractor) { where("extract(dow from jobs.date) != ? OR #{contractor.availability.wed} = ?", 3, true).includes(contractors: [:availability]).references(:availability) }
  scope :thurs, -> (contractor) { where("extract(dow from jobs.date) != ? OR #{contractor.availability.thurs} = ?", 4, true).includes(contractors: [:availability]).references(:availability) }
  scope :fri, -> (contractor) { where("extract(dow from jobs.date) != ? OR #{contractor.availability.fri} = ?", 5, true).includes(contractors: [:availability]).references(:availability) }
  scope :sat, -> (contractor) { where("extract(dow from jobs.date) != ? OR #{contractor.availability.sat} = ?", 6, true).includes(contractors: [:availability]).references(:availability) }
  scope :days, -> (contractor) { sun(contractor).mon(contractor).tue(contractor).wed(contractor).thurs(contractor).fri(contractor).sat(contractor) }

  scope :pickup,  -> { where(occasion_cd: 0) }
  scope :dropoff, -> { where(occasion_cd: 1) }

  before_save :assign_man_hours

  attr_accessor :current_user, :distance

  def self.revenue_on_month date
    jobs = Job.standard.on_month(date).where('bookings.status_cd > 1 and jobs.status_cd > 2').includes(:booking).references(:bookings)
    jobs.reduce(0) {|acc, job| acc + (job.chain(:booking, :prediscount_cost) || 0)} + linen_purchased_revenue_on_month(date)
  end

  def self.linen_purchased_revenue_on_month date
    Property.purchase_on_month(date).reduce(0) {|acc, property| acc + (property.linen_purchase_revenue || 0)}
  end

  def self.restocking_revenue_on_last_month
    1931.00 #Since we are not tracking before discounted restocking charges, we will update this number at the end of every month
  end

  def self.payouts_on_month date
    jobs = Job.standard.on_month(date).where('bookings.status_cd > 1 and jobs.status_cd > 2').includes(:booking).references(:bookings)
    jobs.reduce(0) {|acc, job| acc + job.payouts.reduce(0) {|a,p| a + (p.amount || 0)} } / 100.0
  end

  def self.serviced_on_month date
    Job.standard.complete.on_month(date).count
  end

  def self.properties_on_month date
    Job.standard.complete.on_month(date).to_a.uniq { |job| job.chain(:booking, :property, :id) }.count
  end

  def self.hosts_on_month date
    Job.standard.complete.on_month(date).to_a.uniq { |job| job.chain(:booking, :user, :id) }.count
  end

  def self.jobs_in_week jobs, week, date
    jobs.select {|job| job.date.year == date.year && job.date.month == date.month && week.index(job.date.day)}
  end

  def contractor_payouts
    payouts.map {|payout| if payout.user then "#{payout.user.name} (#{((payout.amount && payout.total || 0) / 100.0)})" end}.compact.join ', '
  end

  def formatted_time
    if booking.then(:timeslot)
      time = booking.timeslot - 1
      meridian = 'A'; meridian = 'P' if time > 11
      time -= 12 if time > 12
      "#{time} #{meridian}M"
    elsif distribution
      if distribution_timeslot
        time = distribution_timeslot - 1
        meridian = 'A'; meridian = 'P' if time > 11
        time -= 12 if time > 12
        "#{time} #{meridian}M"
      else
        '9 AM'
      end
    else
      if current_user
        begin
          hours = Job.organize_day current_user, date, self
          time = hours.index(id) + 8
          meridian = 'A'; meridian = 'P' if time > 11
          time -= 12 if time > 12
          "#{time} #{meridian}M"
        rescue
          'flex'
        end
      else
        'flex'
      end
    end
  end

  def soiled_pickup_count
    if booking
      prev_booking = booking.property.bookings.completed.order('date desc')[0]
      prev_booking.then :linen_set_count
    end
  end

  def king_bed_count
    if booking && has_linens?
      if booking.linen_handling == :in_unit
        booking.extra_king_sets
      else
        booking.property.king_bed_count + booking.extra_king_sets
      end
    else
      0
    end
  end

  def soiled_king_count
    checklist.checklist_settings[:inventory_count]['king_sheets'] if checklist
  end

  def twin_bed_count
    if booking && has_linens?
      if booking.linen_handling == :in_unit
        booking.extra_twin_sets
      else
        booking.property.twin_beds + booking.extra_twin_sets
      end
    else
      0
    end
  end

  def soiled_twin_count
    checklist.checklist_settings[:inventory_count]['twin_sheets'] if checklist
  end

  def toiletry_count
    if booking && has_toiletries?
      if booking.linen_handling == :in_unit
        booking.extra_toiletry_sets
      else
        booking.property.bathrooms + booking.extra_toiletry_sets
      end
    else
      0
    end
  end

  def pillow_count
    king_bed_count * 4
  end

  def soiled_pillow_count
    checklist.checklist_settings[:inventory_count]['pillow_count'] if checklist
  end

  def bath_towel_count
    king_bed_count * 3 + twin_bed_count * 2
  end

  def soiled_bath_towel_count
    checklist.checklist_settings[:inventory_count]['bath_towels'] if checklist
  end

  def bath_mat_count
    king_bed_count
  end

  def soiled_mat_count
    checklist.checklist_settings[:inventory_count]['bath_mats'] if checklist
  end

  def hand_towel_count
    king_bed_count * 2 + twin_bed_count
  end

  def soiled_hand_count
    checklist.checklist_settings[:inventory_count]['hand_towels'] if checklist
  end

  def face_towel_count
    king_bed_count * 2 + twin_bed_count
  end

  def soiled_face_count
    checklist.checklist_settings[:inventory_count]['face_towels'] if checklist
  end

  def contractor_names
    (contractors + payouts.map(&:user)).uniq.compact.map(&:name).join ', '
  end

  def priority contractor=nil
    contractor ||= current_user
    ContractorJobs.where(user_id: contractor.id, job_id: self.id)[0].then(:priority) if contractor
  end

  def payout_amount contractor=nil
    contractor ||= current_user
    payout contractor if contractor
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
    contractor.jobs.on_date(date).where('status_cd in (1,2) AND contractor_jobs.priority > ?', priority(contractor)).order('contractor_jobs.priority').includes(:contractor_jobs).references(:contractor_jobs).first
  end

  def prev_job contractor=nil
    contractor ||= current_user
    contractor.jobs.on_date(date).where('contractor_jobs.priority < ?', priority(contractor)).order('contractor_jobs.priority').includes(:contractor_jobs).references(:contractor_jobs).last
  end

  def payout contractor=nil
    if booking
      if booking.cancelled? || booking.couldnt_access?
        ((booking.original_cost / size) * 0.8).round 2
      else
        contractor ||= current_user
        # payout_multiplier = state == :vip ? 0.75 : 0.7
        payout_multiplier = 0.7
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
        payout += PRICING['laundry_payout'] * booking.property.beds if booking.linen_handling == :in_unit

        if contractor.chain(:contractor_profile, :position) == :trainee
          payout = 20
        else
          if size > 1
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
          else
            payout = 35 if payout < 35
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

  def contractor_photos
    checklist.then(:contractor_photos)
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
      if contractor.jobs.on_date(date).first then false else true end
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
      if contractor.jobs.on_date(date).team.first then true else false end
    end
  end

  def staging
    booking.services.select {|s| s.name == 'preset' }.count > 0 if booking
  end

  def has_linens?
    booking.services.select {|s| s.name == 'linens' }.count > 0
  end

  def has_sets?
    booking.linen_set_count > 0
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
    update_attribute :size, contractors.team_members.count
    inventory_count! if occasion == :dropoff
    pay_contractors!
    booking.update_attribute :status_cd, 3 if booking
    save
  end

  def pay_contractors!
    contractors.each do |contractor|
      unless Payout.where(job_id: self.id, user_id: contractor.id)[0] || !payout(contractor)
        contractor.payouts.create(job_id: self.id, amount: payout(contractor) * 100, payout_type_cd: 0)
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

    if (single_jobs.empty? || !single_jobs.any?(&:has_linens?)) && (!team_job.then(:has_linens?) || team_job.then(:primary_contractor) != user)
      jobs.distribution.destroy_all
    else
      if single_jobs[0]
        distribution_job = user.jobs.create(distribution: true, status_cd: 1, date: date, occasion_cd: 0) unless distribution_job
        single_jobs.each do |job|
          not_complete = true if job.not_complete?
          if job.has_linens?
            supplies[:king_beds] += job.booking.property.king_beds unless job.booking.linen_handling == :in_unit
            supplies[:king_beds] += job.booking.property.queen_beds unless job.booking.linen_handling == :in_unit
            supplies[:king_beds] += job.booking.property.full_beds unless job.booking.linen_handling == :in_unit
            supplies[:king_beds] += job.booking.extra_king_sets
            supplies[:twin_beds] += job.booking.property.twin_beds unless job.booking.linen_handling == :in_unit
            supplies[:twin_beds] += job.booking.extra_twin_sets
          end
          if job.has_toiletries?
            job.booking.property.bathrooms.times { supplies[:toiletries] += 1 }
            supplies[:toiletries] += job.booking.extra_toiletry_sets
          end
        end
      end

      if team_job.then(:primary_contractor) == user
        distribution_job = user.jobs.create(distribution: true, status_cd: 1, date: date, occasion_cd: 0) unless distribution_job
        not_complete = true if team_job.not_complete?
        if team_job.has_linens?
          supplies[:king_beds] += team_job.booking.property.king_beds unless team_job.booking.linen_handling == :in_unit
          supplies[:king_beds] += team_job.booking.property.queen_beds unless team_job.booking.linen_handling == :in_unit
          supplies[:king_beds] += team_job.booking.property.full_beds unless team_job.booking.linen_handling == :in_unit
          supplies[:king_beds] += team_job.booking.extra_king_sets
          supplies[:twin_beds] += team_job.booking.property.twin_beds unless team_job.booking.linen_handling == :in_unit
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

  def self.find_hours hours, range, times
    count = 0; index = nil; ranges=[]
    hours[times[0]..times[1]].each_with_index do |hour, i|
      if hour || i == hours[times[0]..times[1]].length - 1
        count += 1 unless hour
        ranges.push([index, count]) if index && count > range
        count = 0; index = nil
      else
        count += 1
        index ||= i + times[0]
      end
    end
    ranges
  end

  def self.organize_day contractor, date, job=nil, admin=true, timed_job=nil
    hours = []; hours[12] = nil
    jobs  = contractor.jobs.standard.on_date(date)
    count = 0; index = nil

    timed_jobs = jobs.timed
    timed_jobs += [job] if job && (job.booking.timeslot_type == :premium || (job.booking.timeslot && job.size > 1))
    timed_jobs += [timed_job] if timed_job && !timed_jobs.index(timed_job)
    timed_jobs.each do |job|
      start_hour = job.booking.timeslot - 9
      end_hour   = (job.booking.timeslot + job.man_hours).floor - 9
      (start_hour..end_hour).each {|hour| if hours[hour] then raise else hours[hour] = job.id end}
    end

    flex_jobs = jobs.untimed.team + jobs.untimed.single
    flex_jobs += [job] if job && (job.booking.timeslot_type == :flex && (!job.booking.timeslot || job.size == 1))
    flex_jobs -= [timed_job] if timed_job && flex_jobs.index(timed_job)
    # sort by target priority
    flex_jobs.each_with_index do |job, index|
      range  = job.man_hours.floor
      ranges = Job.find_hours hours, range, [2, 7] # base start index on previous job
      if ranges.empty? && admin
        timezone = Timezone::Zone.new :zone => contractor.contractor_profile.zone
        time = timezone.time Time.now
        if time.to_date == date then start = time.hour - 8 else start = 0 end
        ranges = Job.find_hours hours, range, [start, -1] # base start index on previous job
      end
      slot = ranges[0]
      (slot[0]..(range + slot[0])).each {|hour| hours[hour] = job.id}
    end

    hours
  end

  def fits_in_day contractor, admin=false
    begin
      Job.organize_day contractor, date, self, admin
      true
    rescue
      false
    end
  end

  def edit_time time
    orig_timeslot = booking.timeslot
    booking.update_attribute :timeslot, time
    begin
      contractors.each {|contractor| Job.organize_day contractor, date, nil, true, self}
      update_attribute :admin_set, true
      contractors.each {|contractor| Job.set_priorities contractor, date}
      true
    rescue
      booking.update_attribute :timeslot, orig_timeslot
      false
    end
  end

  def check_times
    hours = []; hours[12] = nil
    orig_timeslot = booking.timeslot
    13.times do |time|
      booking.update_attribute :timeslot, time + 9
      begin
        contractors.each {|contractor| Job.organize_day contractor, date, nil, true, self}
        hours[time] = true
      rescue
        hours[time] = false
      end
    end
    booking.update_attribute :timeslot, orig_timeslot
    hours
  end

  def self.set_priorities contractor, date
    jobs = contractor.jobs.on_date(date)
    if jobs.standard.any? {|job| job.booking.timeslot_type_cd == 1 || job.admin_set}
      hours = Job.organize_day(contractor, date).uniq.compact
      hours.each_with_index do |id, index|
        ContractorJobs.where(user_id: contractor.id, job_id: id)[0].update_attribute :priority, index + 1
        job = Job.find id
        if index > 0 then prev_job = Job.find hours[index-1] else prev_job = nil end
        if (!job.booking.timeslot || job.size == 1) && job.booking.timeslot_type_cd == 0 && !job.admin_set
          if prev_job
            job.booking.update_attribute :timeslot, (prev_job.booking.timeslot + prev_job.man_hours).floor + 1
          else
            job.booking.update_attribute :timeslot, 11
          end
        end
      end
      if jobs.distribution.present?
        ContractorJobs.where(user_id: contractor.id, job_id: jobs.pickup[0].id)[0].update_attribute :priority, 0
        ContractorJobs.where(user_id: contractor.id, job_id: jobs.dropoff[0].id)[0].update_attribute :priority, hours.count + 1
        first_job = Job.find hours[0]
        if first_job.booking.timeslot_type == :flex
          jobs.distribution.pickup[0].update_attribute :distribution_timeslot, 10
        else
          jobs.distribution.pickup[0].update_attribute :distribution_timeslot, first_job.booking.timeslot - 1
        end
        centers = DistributionCenter.active.within_market(contractor.contractor_profile.market).map {|center| [center.id, Haversine.distance(center.lat, center.lng, contractor.contractor_profile.lat, contractor.contractor_profile.lng)]}.sort_by {|c| c[1]}
        jobs.pickup[0].distribution_center = DistributionCenter.find centers[0][0]
        centers = DistributionCenter.active.within_market(contractor.contractor_profile.market).map {|center| [center.id, Haversine.distance(center.lat, center.lng, contractor.contractor_profile.lat, contractor.contractor_profile.lng)]}.sort_by {|c| c[1]}
        jobs.dropoff[0].distribution_center = DistributionCenter.find centers[0][0]
        jobs.pickup[0].save; jobs.dropoff[0].save
      end
    else
      paths = []
      (DistributionCenter.active.within_market(contractor.contractor_profile.market).map{|dc| [dc, dc]} + DistributionCenter.active.within_market(contractor.contractor_profile.market).to_a.permutation(2).to_a).each do |dc_permutation|
        jobs.standard.to_a.permutation(jobs.standard.length).to_a.each do |jobs_permutation|
          team_job = jobs.standard.find {|job| job.contractors.count > 1}
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
            next_job = chosen_path[1][index+1]
            if next_job.booking.timeslot_type == :flex
              jobs.distribution.pickup[0].distribution_timeslot = 10
            else
              jobs.distribution.pickup[0].distribution_timeslot = next_job.booking.timeslot - 1
            end
            jobs.distribution.pickup[0].save
          else
            jobs.distribution.dropoff[0].distribution_center = location
            ContractorJobs.where(job_id: jobs.distribution.dropoff[0].id, user_id: contractor.id)[0].update_attribute :priority, index
            jobs.distribution.dropoff[0].save
          end
        else
          ContractorJobs.where(job_id: location.id, user_id: contractor.id)[0].update_attribute :priority, index
          if index > 0 then prev_job = chosen_path[1][index-1] else prev_job = nil end
          if location.booking.timeslot_type == :flex
            if prev_job && prev_job.class != DistributionCenter
              location.booking.update_attribute :timeslot, (prev_job.booking.timeslot + prev_job.man_hours).floor + 1
            else
              location.booking.update_attribute :timeslot, 11
            end
          end
        end
      end
    end
  end

  private

  def assign_man_hours
    if booking
      hours = MAN_HRS[booking.property.property_type.to_s][booking.property.bedrooms][booking.property.bathrooms] / size
      hours += 1 if booking.linen_handling == :in_unit
      self.man_hours = (hours * 2).round / 2.0
    end
  end
end

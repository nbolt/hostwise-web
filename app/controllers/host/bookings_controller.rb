class Host::BookingsController < Host::AuthController
  expose(:property) { Property.find_by_slug params[:slug] }
  expose(:booking)  { Booking.find_by_id params[:booking] }

  def show
    render json: booking.to_json(include: [:services, :payment])
  end

  def update
    if params[:services]
      booking.payment = Payment.find params[:payment] if params[:payment]
      booking.services.each do |service|
        booking.services.destroy service unless params[:services].find {|s| service.name == s}
      end
      params[:services].each do |service|
        booking.services.push Service.where(name: service)[0] unless booking.services.find {|s| service == s.name}
      end
      if params[:extra_instructions].present?
        booking.extra_instructions = params[:extra_instructions]
      end
      if params[:extra_king_sets].present?
        booking.extra_king_sets = params[:extra_king_sets]
      end
      if params[:extra_twin_sets].present?
        booking.extra_twin_sets = params[:extra_twin_sets]
      end
      if params[:extra_toiletry_sets].present?
        booking.extra_toiletry_sets = params[:extra_toiletry_sets]
      end
      booking.coupons.push(Coupon.find params[:coupon_id]) if params[:coupon_id]
      if params[:timeslot]
        if params[:timeslot] == 'flex'
          booking.timeslot = nil
          booking.timeslot_type_cd = 0
        else
          booking.timeslot = params[:timeslot]
          booking.timeslot_type_cd = 1
        end
        booking.job.contractors.each do |contractor|
          if booking.job.fits_in_day contractor
            Job.set_priorities contractor, booking.date
          else
            contractor.drop_job booking.job
          end
        end
      end
      if params[:handling]
        booking.update_attribute :linen_handling_cd, params[:handling]
        property.update_attribute :linen_handling_cd, params[:handling]
      end
      if booking.save
        booking.update_cost!
        booking.job.handle_distribution_jobs booking.job.primary_contractor if booking.job.primary_contractor
        render json: { success: true }
      else
        render json: { success: false }
      end
    else
      render json: { success: false, message: 'Please select at least one service' }
    end
  end

  def cancel
    unless booking.status == :cancelled || booking.status == :deleted
      UserMailer.cancelled_booking_notification(booking).then(:deliver)

      if params[:apply_fee]
        booking.update_attribute :status, :cancelled
      else
        booking.update_attribute :status, :deleted
      end

      if booking.job
        booking.job.update_attribute :status_cd, 6
        booking.job.contractors.each do |contractor|
          contractor.payouts.create(job_id: booking.job.id, amount: booking.job.payout(contractor) * 100) if params[:apply_fee]
          booking.job.contractors.destroy contractor
          other_jobs = contractor.jobs.standard.on_date(booking.date)
          if other_jobs[0]
            other_jobs[0].handle_distribution_jobs contractor
            Job.set_priorities contractor, booking.date
          else
            contractor.jobs.distribution.on_date(booking.date).destroy_all
          end
          if contractor.contractor_profile.position == :trainee
            TwilioJob.perform_later("+1#{contractor.phone_number}", "Oops! Your Test & Tips session on #{booking.job.formatted_date} was cancelled. Please select another session!")
          else
            TwilioJob.perform_later("+1#{contractor.phone_number}", "Oops! Looks like job ##{booking.job.id} on #{booking.job.formatted_date} was cancelled. Sorry about this!")
          end
        end
      end

      if params[:apply_fee]
        booking.update_cost!
        UserMailer.booking_same_day_cancellation(booking).then(:deliver)
      else
        UserMailer.booking_cancellation(booking).then(:deliver)
      end
    end
    render json: { success: true }
  end

  def same_day_cancellation
    render json: { same_day_cancellation: booking.same_day_cancellation }
  end

  def apply_discount
    coupon = Coupon.where(code: params[:code])[0]
    timezone = Timezone::Zone.new :zone => Property.find(params[:property_id]).zone
    time = timezone.time Time.now
    today = time.to_date
    if coupon && coupon.status == :active && (coupon.limit == 0 || coupon.applied(current_user) < coupon.limit) && (!coupon.expiration || coupon.expiration >= today) && (coupon.users.empty? || coupon.users.find current_user.id)
      amount = coupon.amount / 100.0
      amount = params[:total].to_i * (coupon.amount / 100.0) if coupon.discount_type == :percentage
      remaining = -1
      remaining = coupon.limit - coupon.applied(current_user) if coupon.limit > 0
      render json: { success: true, remaining: remaining, coupon_id: coupon.id, display_amount: coupon.display_amount.gsub(/\s+/, ''), amount: amount }
    else
      render json: { success: false }
    end
  end
end

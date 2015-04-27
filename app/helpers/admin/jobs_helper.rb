module Admin::JobsHelper
  def property_id(job)
    if job.booking != nil
      job.booking.property.id
    else
      ''
    end
  end

  def bed_bath(job)
    if job.booking != nil
      "#{job.booking.property.bedrooms}BD/#{job.booking.property.bathrooms}BA"
    else
      'none'
    end
  end

  def address(job)
    if job.booking != nil
      job.booking.property.short_address
    else
      ''
    end
  end

  def host(job)
    if job.booking != nil
      job.booking.property.user.name
    else
      ''
    end
  end

  def host_email(job)
    if job.booking != nil
      job.booking.property.user.email
    else
      ''
    end
  end

  def date_booked(job)
    if job.booking != nil
      job.booking.created_at.strftime '%Y-%m-%d'
    else
      ''
    end
  end

  def phone_number(job)
    if job.booking != nil
      job.booking.property.user.display_phone_number
    else
      ''
    end
  end

  def cost(job)
    if job.booking != nil
      job.booking.cost
    else
      ''
    end
  end

  def king_sets(job)
    if job.booking != nil
      job.booking.property.king_beds
    else
      ''
    end
  end

  def twin_sets(job)
    if job.booking != nil
      job.booking.property.twin_beds
    else
      ''
    end
  end

  def bathrooms(job)
    if job.booking != nil
      job.booking.property.bathrooms
    else
      ''
    end
  end

  def service_list(job)
    if job.booking != nil
      job.booking.service_list
    else
      ''
    end
  end
end
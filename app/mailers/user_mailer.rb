class UserMailer < MandrillMailer::TemplateMailer

  default from: 'support@useporter.com'
  default from_name: 'Porter'

  DEFAULT_REPLY_TO = 'Porter<support@useporter.com>'

  def welcome(user)
    mandrill do
      mandrill_mail template: 'welcome',
                    subject: 'Thank you for joining our community!',
                    to: {email: user.email, name: user.name},
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def booking_reminder(booking)
    mandrill do
      mandrill_mail template: 'appointment-reminder',
                    subject: 'Just a friendly reminder about your services tomorrow.',
                    to: {email: booking.property.user.email, name: booking.property.user.name},
                    vars: {'ADDR' => booking.property.short_address},
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def booking_confirmation(booking)
    mandrill do
      appt_date = booking.date.strftime('%b %e/%Y')
      mandrill_mail template: 'booking-confirmation',
                    subject: "Your services have been booked on #{appt_date} at #{booking.property.short_address}",
                    to: {email: booking.property.user.email, name: booking.property.user.name},
                    vars: {'ADDR' => booking.property.short_address,
                           'DATE' => appt_date},
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def property_confirmation(property)
    mandrill do
      mandrill_mail template: 'property-confirmation',
                    subject: "You've added a new propery at #{property.short_address}",
                    to: {email: property.user.email, name: property.user.name},
                    vars: {'ADDR' => property.short_address},
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def service_completed(property)
    mandrill do
      mandrill_mail template: 'service-completed',
                    subject: "Your services have been completed at #{property.short_address}",
                    to: {email: property.user.email, name: property.user.name},
                    vars: {'ADDR' => property.short_address},
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  private

  def mandrill
    yield if Rails.env.production?
  end
end

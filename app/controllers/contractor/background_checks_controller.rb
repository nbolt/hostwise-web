require 'rest_client'

class Contractor::BackgroundChecksController < Contractor::AuthController
  def create
    dob = current_user.contractor_profile.dob
    formatted_dob = [dob[4..dob.length-1], dob[0..1], dob[2..3]].join '-'
    ssn = "#{current_user.contractor_profile.ssn[0..2]}-#{current_user.contractor_profile.ssn[3..4]}-#{current_user.contractor_profile.ssn[5..8]}"
    application = {first_name: current_user.first_name,
                   last_name: current_user.last_name,
                   email: current_user.email,
                   phone: current_user.phone_number,
                   zipcode: current_user.contractor_profile.zip,
                   dob: formatted_dob,
                   ssn: Rails.env.production? ? ssn : '111-11-2001',
                   custom_id: current_user.id}

    BackgroundCheckSubmissionJob.perform_later(current_user, application)

    render nothing: true
  end
end

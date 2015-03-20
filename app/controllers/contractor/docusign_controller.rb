class Contractor::DocusignController < Contractor::AuthController
  def create
    DocusignSubmissionJob.perform_later(current_user)

    render nothing: true
  end
end

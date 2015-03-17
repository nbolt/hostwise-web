class Contractor::QuizController < Contractor::AuthController
  def report
    quiz = QuizStage.new
    quiz.score = params[:score]
    quiz.pass = params[:pass]
    quiz.took_at = Job.standard.past(current_user).count
    quiz.contractor_profile = current_user.contractor_profile
    quiz.save
    render json: { success: true }
  end
end

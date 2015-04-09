class Admin::TransactionsController < Admin::AuthController
  expose(:transaction) { Transaction.find params[:id] }

  def index
    transactions = Transaction.all

    respond_to do |format|
      format.html
      format.json do
        render json: transactions
      end
    end
  end

end

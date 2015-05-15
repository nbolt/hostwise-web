class Host::TransactionsController < Host::AuthController
  def show
    transaction = Transaction.find params[:id]
    bookings = transaction.bookings.where('properties.user_id = ?', current_user.id).includes(:property).references(:properties)
    render json: bookings, each_serializer: TransactionBookingSerializer, root: :bookings
  end
end

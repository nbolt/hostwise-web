class Host::TransactionsController < Host::AuthController
  def show
    render json: Transaction.find(params[:id]).bookings, each_serializer: TransactionBookingSerializer, root: :bookings
  end

  def booking
    render json: [Booking.find(params[:id])], each_serializer: TransactionBookingSerializer, root: :bookings
  end
end

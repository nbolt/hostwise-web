require 'test_helper'

describe Host::PaymentsController do
  it 'exposes payments' do
    user_name_14 = nil
    credit_card = create(:credit_card)
    VCR.use_cassette('create_user_name_14') { user_name_14 = create(:user_name_14) }
    #assert_response :success
  end
end
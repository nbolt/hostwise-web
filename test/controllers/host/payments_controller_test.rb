require 'test_helper'

describe Host::PaymentsController do
  it 'exposes payments' do
    user_name_14 = nil
    credit_card = create(:credit_card)
    VCR.use_cassette('create_user_name_14') { user_name_14 = create(:user_name_14) }
    login_user(user_name_14)
    binding.pry
    get(:add, :id => credit_card.id)

    assert_response :success
  end
end
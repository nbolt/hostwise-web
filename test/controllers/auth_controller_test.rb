require 'test_helper'

describe AuthController do
  it 'auth' do
    get :auth
    assert_redirected_to '/signin'

    user_name_13 = nil
    VCR.use_cassette('create_user_name_13') { user_name_13 = create(:user_name_13) }
    login_user(user_name_13)
  end

  it 'phone_confirmed' do
    user_name_13 = nil
    VCR.use_cassette('create_user_name_13') { user_name_13 = create(:user_name_13) }
    get(:phone_confirmed, :email => 'dustinj593@gmail.com')
  end

  it 'signup' do
    user_name_13 = nil
    VCR.use_cassette('create_user_name_13') { user_name_13 = create(:user_name_13) }
    user_name_13.phone_confirmed = true
    user_name_13.save
  end

  it 'signin' do
  end
end
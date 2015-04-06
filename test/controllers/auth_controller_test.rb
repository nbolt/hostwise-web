require 'test_helper'

describe AuthController do
  it 'auth' do
    get :auth
    assert_redirected_to '/signin'

    user_name_13 = nil
    VCR.use_cassette('create_user_name_13') { user_name_13 = create(:user_name_13) }
    login_user(user_name_13)

    :subdomain.must_equal 'test'
  end

  it 'phone_confirmed do' do
    user_name_13 = nil
    VCR.use_cassette('create_user_name_13') { user_name_13 = create(:user_name_13) }
    get(:phone_confirmed, :email => 'dustinj593@gmail.com')
  end
end
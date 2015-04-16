require 'test_helper'

describe Admin::HomeController do 
  it 'index' do
    user_name_11 = nil
    VCR.use_cassette('create_user_name_11') { user_name_11 = create(:user_name_11) }
    login_user(user_name_11)

    get :index
    assert_redirected_to  '/jobs'
  end
end
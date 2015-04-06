require 'test_helper'

describe Admin::AuthController do
  it 'login_as' do
    user_name_11 = nil
    VCR.use_cassette('create_user_name_11') { user_name_11 = create(:user_name_11) }
    get(:login_as, :id => user_name_11.id)
    #assert_response :success
    #assert_redirected_to '/'
  end
end
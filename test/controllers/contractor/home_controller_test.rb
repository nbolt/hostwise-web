require 'test_helper'

describe Contractor::HomeController do
  it 'index' do
    user_name_10 = nil
    VCR.use_cassette('create_user_name_10') { user_name_10 = create(:user_name_10) }
    login_user(user_name_10)

    get :index
    must_render_template 'contractor/index'

    user_name_6 = nil
    VCR.use_cassette('create_user_name_6') { user_name_6 = create(:user_name_6) }
    login_user(user_name_6)

    get :index
    assert_redirected_to '/quiz'
  end

  it 'contact' do
    user_name_10 = nil
    VCR.use_cassette('create_user_name_10') { user_name_10 = create(:user_name_10) }
    login_user(user_name_10)

    get :contact
    must_render_template 'common/_contact'
  end
end
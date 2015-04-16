require 'test_helper'

describe Contractor::HomeController do
  it 'index' do
    user_name_10 = nil
    VCR.use_cassette('create_user_name_10') { user_name_10 = create(:user_name_10) }
    login_user(user_name_10)

    get :index
    must_render_template 'contractor/index'

    logout_user

    user_name_6 = nil
    VCR.use_cassette('create_user_name_6') { user_name_6 = create(:user_name_6) }
    login_user(user_name_6)

    get :index
    assert_redirected_to '/quiz'

    logout_user

    profile_4 = nil, user_name_18 = nil, profile_4 = nil
    VCR.use_cassette('create_profile_4') { profile_4 = create(:profile_4) }
    profile_4.must_equal profile_4
    VCR.use_cassette('create_user_name_18') { user_name_18 = create(:user_name_18) }
    user_name_18.contractor_profile = profile_4
    user_name_18.save
    login_user(user_name_18)
  end

  it 'contact' do
    user_name_10 = nil
    VCR.use_cassette('create_user_name_10') { user_name_10 = create(:user_name_10) }
    login_user(user_name_10)

    get :contact
    must_render_template 'common/_contact'
  end
end
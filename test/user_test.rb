class PlantSchedulerTest < Minitest::Test
  def test_view_home
    get "/home"

    assert_equal 200, last_response.status
    assert_includes last_response.body, ">Log In</a>"
    assert_includes last_response.body, 'href="/admin">admin</a>'
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  end

  def test_view_home_logged_in
    get "/home", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Log Out</a>"
    assert_includes last_response.body, 'brand" href="/admin">'
    refute_includes last_response.body, ">Log In</a>"
  end

  def test_root_redirect_to_home
    get "/"

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, "admin</a>"
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  end

  def test_view_login_page
    get "/login"

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'col-form-label-sm">Username:'
  end

  def test_redirect_view_login_page_logged_in
    get "/login", {}, admin_session

    assert_equal 302, last_response.status
    assert_equal "You are already logged in!", session[:message]
    get last_response["Location"]
    assert_includes last_response.body, "look at everyone's plants"
  end

  def test_login_user
    post "/signin", { username: 'admin', password: 'secret' }

    assert_equal 302, last_response.status
    assert_equal "Welcome back admin!", session[:message]
    assert_equal 'admin', session[:username]
  end

  def test_login_user_already_logged_in
    post "/signin", { username: 'admin', password: 'secret' }, admin_session

    assert_equal 302, last_response.status
    assert_equal "You are already logged in!", session[:message]
  end

  def test_logout_user
    get "/logout", {}, admin_session

    assert_equal 302, last_response.status
    assert_equal "You have successfully logged out", session[:message]
    assert_nil session[:username]
  end

  def test_logout_user_not_logged_in
    get "logout"

    assert_equal 302, last_response.status
    assert_equal "You are not logged in!", session[:message]
  end

  def test_view_signup_page
    get "/signup"

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'col-form-label-sm">Confirm Password:'
  end

  def test_view_signup_page_logged_in
    get "/signup", {}, admin_session

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, "look at everyone's plants"
  end

  def test_signup_new_user
    post "/signup", { username: 'test', password: 'testpass', password_confirm: 'testpass' }

    assert_equal 302, last_response.status
    assert_equal "Welcome test!", session[:message]
    assert_equal 'test', session[:username]
    File.write(access_file_path("users.yml"), { 'admin' => BCrypt::Password.create('secret') }.to_yaml)
  end

  def test_signup_new_user_username_taken
    post "/signup", { username: 'admin', password: 'testpass', password_confirm: 'testpass' }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "That username is taken already."
  end

  def test_signup_new_user_long_username
    username = 'test long username that will fail'
    post "/signup", { username: username, password: 'testpass', password_confirm: 'testpass' }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Your username must be between 2 and 25"
  end

  def test_signup_new_user_short_username
    post "/signup", { username: '', password: 'testpass', password_confirm: 'testpass' }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Your username must be between 2 and 25"
  end

  def test_signup_new_user_short_password
    post "/signup", { username: 'test', password: 'pass', password_confirm: 'pass' }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Your password must contain at least 6 characters."
  end

  def test_signup_new_user_not_matching_passwords
    post "/signup", { username: 'test', password: 'testpass', password_confirm: 'testpasses' }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Your passwords must be matching."
  end

  def test_signup_new_user_logged_in
    post "/signup", { username: 'test', password: 'testpass', password_confirm: 'testpasses' }, admin_session

    assert_equal 302, last_response.status
    assert_equal "You are already logged in!", session[:message]
  end

  def test_user_page_current_user_logged_in
    create_plants_datafile_with_one_default_plant

    get "/admin", {}, admin_session

    assert_equal 200, last_response.status
    include_trash_and_water_icons(:assert_includes)
    assert_includes last_response.body, "You have 1 plant. It needs a friend!"

    default_plant_assert_includes_five_info_types
  end

  def test_user_page_not_current_user_logged_in
    create_plants_datafile_with_one_default_plant

    get "/admin", {}, { "rack.session" => { username: 'test' } }

    assert_equal 200, last_response.status
    include_trash_and_water_icons(:refute_includes)
    assert_includes last_response.body, "admin is currently caring for 1 plant."

    default_plant_assert_includes_five_info_types
  end

  def test_user_page_not_logged_in
    create_plants_datafile_with_one_default_plant

    get "/admin"

    assert_equal 200, last_response.status
    include_trash_and_water_icons(:refute_includes)
    assert_includes last_response.body, "admin is currently caring for 1 plant."

    default_plant_assert_includes_five_info_types
  end

  def test_view_new_plant_page_current_user_logged_in
    get "/admin/new", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'col-form-label-sm">Link to'
    assert_includes last_response.body, 'outline-success">Grow your'
  end

  def test_view_new_plant_page_not_current_user
    get "/admin/new", {}, { "rack.session" => { username: 'test' } }

    no_access_assert_status_and_session_message
  end
end

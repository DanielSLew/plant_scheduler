require "sinatra"
require "sinatra/reloader" if development?

require "tilt/erubis"
require "yaml"
require "fileutils"

require "bcrypt"
require "securerandom"

require_relative "lib/plant_scheduler_helper_methods"
require_relative "lib/html_helper_methods"

configure do
  enable :sessions
  set :erb, escape_html: true
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
end

before "/:user/:plant_id/*" do
  @username = params[:user]
  @plant_id = params[:plant_id].to_i

  required_current_user(@username)
end

before "/:user/*" do
  @username = params[:user]

  required_current_user(@username)
end

get "/" do
  redirect "/home"
end

# Renders the Home Page
get "/home" do
  @users = load_user_credentials.keys
  erb :home
end

# Renders the login page
get "/login" do
  required_logged_out_user

  erb :login
end

# Logs in a user
post "/signin" do
  required_logged_out_user

  username, password = params[:username], params[:password]

  if valid_credentials?(username, password)
    session[:username] = username
    session[:message] = "Welcome back #{username}!"
    redirect "/"
  else
    status 422
    session[:message] = 'Invalid login info!'
    erb :login
  end
end

# Logs out a user
get "/logout" do
  if !session[:username]
    session[:message] = "You are not logged in!"
    redirect "/"
  end

  session.delete(:username)
  session[:message] = "You have successfully logged out"
  redirect "/"
end

# Renders the signup page
get "/signup" do
  required_logged_out_user

  erb :signup
end

# Signs up a new user
post "/signup" do
  required_logged_out_user

  username, password = params[:username], params[:password]
  credentials        = load_user_credentials

  if invalid_signup_message(credentials, username, password, params[:password_confirm])
    status 422
    erb :signup
  else
    credentials[username] = BCrypt::Password.create(password)
    update_users(credentials)

    session[:username]    = username
    session[:message]     = "Welcome #{username}!"
    redirect "/"
  end
end

# Render a user page
get "/:user" do
  @username = params[:user]

  plants    = load_plants_file[@username] || []
  @plants   = sort_by_unwatered(plants)
  erb :user
end

# Render the new plant page
get "/:user/new" do
  erb :new_plant
end

# Add a new plant to a user
post "/:user/new" do
  format_plant_info(params)

  if invalid_plant_input
    status 422
    erb :new_plant
  else
    add_new_plant(@username)
    session[:message] = "Your plant family has sprouted a new friend!"
    redirect "/#{@username}"
  end
end

# Delete a current user's plant
post "/:user/:plant_id/delete" do
  plants = load_plants_file[@username]
  plant_does_not_exist(@username) unless plants[@plant_id]

  plants.delete(@plant_id)
  update_plant_file(plants)

  session[:message] = "We're mourning the loss of your plant as well"
  redirect "/#{@username}"
end

# Water a current user's plant
post "/:user/:plant_id/water" do
  plants = load_plants_file
  plant  = plants[@username][@plant_id]

  plant_does_not_exist(@username) unless plant

  water_plant(plant)
  update_plant_file(plants)

  session[:message] = "You've watered your plant!"
  redirect "/#{@username}"
end

# Render view edit page for plant
get "/:user/:plant_id/edit" do
  plant_info = []
  plant      = load_plants_file[@username][@plant_id]

  PLANT_INFO_TYPES.each_with_index do |info, idx|
    plant_info[idx] = plant[info]
  end

  @type, @photo, @schedule, @last_water, @notes = plant_info

  erb :edit_plant
end

# Updates a plant
post "/:user/:plant_id/edit" do
  updated_info = params[:type], params[:photo], params[:schedule], [Date.today], params[:notes]
  @type, @photo, @schedule, @last_water, @notes = updated_info

  if invalid_plant_input
    status 422
    erb :edit_plant
  else
    plants = load_plants_file
    plant  = plants[@username][@plant_id]

    update_plant_info(plant, updated_info, skip: 'last_water')
    update_plant_file(plants)

    session[:message] = "The info was successfully updated!"
    redirect "/#{@username}"
  end
end

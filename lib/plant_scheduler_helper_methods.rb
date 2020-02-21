##### File and Directory helper methods

# Finds the root directory based off of working environment
def access_file_path(path)
  if ENV["RACK_ENV"] == 'test'
    File.expand_path("../../test/#{path}", __FILE__)
  else
    File.expand_path("../../#{path}", __FILE__)
  end
end

# Returns the working data path as a string
def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../../test/data", __FILE__)
  else
    File.expand_path("../../data", __FILE__)
  end
end

# Returns a hash with username => password
def load_user_credentials
  credentials_filepath = access_file_path("users.yml")
  YAML.load_file(credentials_filepath) || {}
end

# Updates new user to users.yml
def update_users(credentials)
  File.open(access_file_path("users.yml"), 'w') { |f| f.write credentials.to_yaml }
end

# Returns a hash of users => plants
def load_plants_file
  YAML.load_file(File.join(data_path, "plants.yml")) || {}
end

# Updates the plant file
def update_plant_file(plants)
  File.open(File.join(data_path, "plants.yml"), 'w') { |f| f.write plants.to_yaml }
end
#####

##### User Checks

# Redirects user if not authorized user
def required_current_user(user)
  return unless user != session[:username]

  session[:message] = "Only #{user} has access to do this"
  redirect "/#{user}"
end

# Redirects to home if you try to access a page for logged out users
def required_logged_out_user
  return unless session[:username]

  session[:message] = "You are already logged in!"
  redirect "/home"
end

# Uses BCrypt to check if credentials match, returns nil if no match.
def valid_credentials?(username, password)
  credentials = load_user_credentials

  return unless credentials.key?(username)

  bcrypt_password = BCrypt::Password.new(credentials[username])
  bcrypt_password == password
end
#####

##### Input Validation

# Sets an invalid signup message if the signup info is invalid, returns nil otherwise
def invalid_signup_message(credentials, username, password, password_confirm)
  if credentials.find { |user, _| user == username }
    session[:message] = "That username is taken already."
  elsif !(2..25).cover? username.length
    session[:message] = "Your username must be between 2 and 25 characters"
  elsif password != password_confirm
    session[:message] = "Your passwords must be matching."
  elsif password.length < 6
    session[:message] = "Your password must contain at least 6 characters."
  end
end

# Sets a session message if the input is invalid
def invalid_plant_input
  if !(1..100).cover? @type.size
    session[:message] = "Don't forget to add in a Type!"
  elsif !format_image_url(@photo)
    session[:message] = "Make sure the image has a valid URL"
  elsif !('1'..'7').cover? @schedule
    session[:message] = "The watering schedule has to be between 1 and 7!"
  elsif @last_water.first.nil?
    session[:message] = "Make sure you specify how many days ago it was watered!"
  elsif @notes.length > 100
    session[:message] = "Your note is too long, be more concise (less than 100 characters)!"
  end
end
#####

##### Format data to workable input

# Returns the next highest id number available
def next_plant_id(plants)
  max = plants.map { |id, _| id }.max || 0
  max + 1
end

# Returns nil if it can't match a an image in the URL, modifies the image_url to only contain the image if match
def format_image_url(image_url)
  image_url.sub!(/((.*\.(jpg|jpeg|gif|png)).*)/, '\2') || image_url.empty?
end

# Sets instance variables and formats plant info
def format_plant_info(info)
  info[:photo]     = "/default-plant.png" if info[:photo].empty?
  unformatted_info = [info[:type], info[:photo], info[:schedule], info[:notes]]

  @plant_info      = unformatted_info.map(&:strip)
  @plant_info.insert(3, [date_of_last_water(info[:last_water])])

  @type, @photo, @schedule, @last_water, @notes = @plant_info
end

# Returns a Date object of last water, or nil if invalid input
def date_of_last_water(num_of_days)
  return nil if num_of_days.strip =~ /[^0-9]/
  Date.today - num_of_days.strip.to_i
end
#####

##### Plant data helper methods

PLANT_INFO_TYPES = ['type', 'photo', 'schedule', 'last_water', 'notes']

# Adds a new plant to the user
def add_new_plant(user)
  plants         = load_plants_file
  new_plant_info = {}

  PLANT_INFO_TYPES.each_with_index do |category, idx|
    new_plant_info[category] = @plant_info[idx]
  end

  plants[user]           = {} unless plants[user]
  plant_id               = next_plant_id(plants[user])
  plants[user][plant_id] = new_plant_info

  update_plant_file(plants)
end

# Updates the info for a plant, with option to skip info.
def update_plant_info(plant, updated_info, skip: nil)
  plant.each_with_index do |(info, _), idx|
    next if info == skip
    plant[info] = updated_info[idx]
  end
end

# Redirects to user if from a non-existant plant URL
def plant_does_not_exist(user)
  session[:message] = "That plant doesn't exist"
  redirect "/#{user}"
end

# Pushes a Date object set to today into the 'last_water' array.
def water_plant(plant)
  current_week = Date.today.cweek
  plant['last_water'].delete_if { |date| date.cweek != current_week }
  plant['last_water'] << Date.today
end

# Sorts remaining waters left for the week
def sort_by_unwatered(plants)
  plants.sort_by { |_, plant| watering_count(plant) - plant['schedule'].to_i }
end
#####

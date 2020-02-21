def add_plant(user, type="", photo="", schedule="", last_water=[Date.today], notes="")
  @plant_info = type, photo, schedule, last_water, notes
  add_new_plant(user)
end

def create_plants_datafile
  plants = { 'admin' => {} }
  File.open(File.join(data_path, 'plants.yml'), 'w') { |f| f.write plants.to_yaml }
end

def create_plants_datafile_with_one_default_plant
  create_plants_datafile
  add_plant('admin', 'pothos', 'pothos.jpg', '3', [Date.new(2020)], 'Bedroom')
end

def session
  last_request.env["rack.session"]
end

def admin_session
  { "rack.session" => { username: "admin" } }
end

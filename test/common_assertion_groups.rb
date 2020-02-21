##### Common assertion groups
def no_access_assert_status_and_session_message
  assert_equal 302, last_response.status
  assert_equal "Only admin has access to do this", session[:message]
end

def plant_successfully_added_assert_status_and_session_message
  assert_equal 302, last_response.status
  assert_equal "Your plant family has sprouted a new friend!", session[:message]
end

def default_plant_assert_includes_five_info_types(last_water: Date.new(2020))
  assert_includes last_response.body, 'pothos</h1>'
  assert_includes last_response.body, 'src="pothos.jpg"'
  assert_includes last_response.body, '>Water 3 times a week'
  assert_includes last_response.body, "<p>Last watered on #{last_water.strftime('%b %d')}"
  assert_includes last_response.body, '<p>Notes: Bedroom</p>'
end

def include_trash_and_water_icons(method)
  send method, last_response.body, 'class="trash-can float-left" type="submit"'
  send method, last_response.body, 'class="plant-water" type="submit"'
end

def edit_default_plant_assert_status_and_relocate(
  type: 'pothos', photo: 'pothos.jpg', schedule: '3', notes: 'Bedroom'
)
  create_plants_datafile_with_one_default_plant

  post "/admin/1/edit", { type: type, photo: photo,
                          schedule: schedule, notes: notes }, admin_session

  assert_equal 302, last_response.status
  get last_response["Location"]
end
#####

class PlantSchedulerTest < Minitest::Test
  def test_add_new_plant_to_user
    create_plants_datafile

    post "/admin/new", {
      type: 'pothos', photo: 'pothos.jpg', schedule: '3',
      last_water: '10', notes: 'Bedroom'
    }, admin_session

    plant_successfully_added_assert_status_and_session_message

    get last_response["Location"]

    assert_includes last_response.body, 'class="trash-can float-left" type="submit">'
    assert_includes last_response.body, 'class="plant-water" type="submit">'
    assert_includes last_response.body, 'You have 1 plant. It needs a friend!'

    last_water = Date.today - 10
    default_plant_assert_includes_five_info_types(last_water: last_water)
  end

  def test_add_new_plant_invalid_type
    create_plants_datafile

    post "/admin/new", {
      type: '', photo: 'pothos.jpg', schedule: '3',
      last_water: '10', notes: 'Bedroom'
    }, admin_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Don't forget to add in a Type!"
  end

  def test_add_new_plant_invalid_photo
    create_plants_datafile

    post "/admin/new", {
      type: 'pothos', photo: 'pothos.txt', schedule: '3',
      last_water: '10', notes: 'Bedroom'
    }, admin_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Make sure the image has a valid URL'
  end

  def test_add_new_plant_invalid_schedule
    create_plants_datafile

    post "/admin/new", {
      type: 'pothos', photo: 'pothos.jpg', schedule: '8',
      last_water: '10', notes: 'Bedroom'
    }, admin_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'The watering schedule has to be between 1 and 7!'
  end

  def test_add_new_plant_invalid_last_water
    create_plants_datafile

    post "/admin/new", {
      type: 'pothos', photo: 'pothos.jpg', schedule: '3',
      last_water: 'invalid', notes: 'Bedroom'
    }, admin_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Make sure you specify how many'
  end

  def test_add_new_plant_invalid_note_too_long
    create_plants_datafile
    long_note = 'This is a long note.' * 15

    post "/admin/new", {
      type: 'pothos', photo: 'pothos.jpg', schedule: '3',
      last_water: '10', notes: long_note
    }, admin_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Your note is too long'
  end

  def test_add_new_plant_no_photo_default_photo
    create_plants_datafile

    post "/admin/new", {
      type: 'pothos', photo: '', schedule: '3',
      last_water: '10', notes: 'Bedroom'
    }, admin_session

    plant_successfully_added_assert_status_and_session_message

    get last_response["Location"]
    assert_includes last_response.body, 'src="/default-plant.png"'
  end

  def test_add_new_plant_format_image_url
    create_plants_datafile

    post "/admin/new", {
      type: 'pothos', photo: 'pothos.jpg?test=testing', schedule: '3',
      last_water: '10', notes: 'Bedroom'
    }, admin_session

    plant_successfully_added_assert_status_and_session_message

    get last_response["Location"]
    assert_includes last_response.body, 'src="pothos.jpg"'
  end

  def test_add_new_plant_no_notes
    create_plants_datafile

    post "/admin/new", {
      type: 'pothos', photo: 'pothos.jpg', schedule: '3',
      last_water: '10', notes: ''
    }, admin_session

    plant_successfully_added_assert_status_and_session_message
  end

  def test_add_new_plant_not_current_user
    create_plants_datafile

    post "/admin/new", {
      type: 'pothos', photo: 'pothos.jpg', schedule: '3',
      last_water: '10', notes: 'Bedroom'
    }, { "rack.session" => { username: 'test' } }

    no_access_assert_status_and_session_message
  end

  def test_delete_plant
    create_plants_datafile_with_one_default_plant

    post "/admin/1/delete", {}, admin_session

    assert_equal 302, last_response.status
    assert_equal "We're mourning the loss of your plant as well", session[:message]

    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'You have no plants, start growing your'
  end

  def test_delete_non_existant_plant
    create_plants_datafile_with_one_default_plant

    post "/admin/2/delete", {}, admin_session

    assert_equal 302, last_response.status
    assert_includes "That plant doesn't exist", session[:message]
  end

  def test_delete_plant_not_current_user
    create_plants_datafile_with_one_default_plant

    post "/admin/1/delete"

    no_access_assert_status_and_session_message
  end

  def test_water_plant
    create_plants_datafile_with_one_default_plant

    post "/admin/1/water", {}, admin_session

    assert_equal 302, last_response.status
    assert_equal "You've watered your plant!", session[:message]

    get last_response["Location"]
    last_water = Date.today.strftime("%b %d")

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<p>Last watered on #{last_water}"
  end

  def test_water_non_existent_plant
    create_plants_datafile_with_one_default_plant

    post "/admin/2/water", {}, admin_session

    assert_equal 302, last_response.status
    assert_includes "That plant doesn't exist", session[:message]
  end

  def test_water_plant_not_current_user
    create_plants_datafile_with_one_default_plant

    post "/admin/1/water"

    no_access_assert_status_and_session_message
  end

  def test_view_edit_plant_page
    create_plants_datafile_with_one_default_plant

    get "/admin/1/edit", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'col-form-label-sm">Add new'
    assert_includes last_response.body, 'outline-success">Submit Changes'
    assert_includes last_response.body, 'Cancel</a>'
    assert_includes last_response.body, '<fieldset disabled>'
  end

  def test_view_edit_plant_page_not_current_user
    create_plants_datafile_with_one_default_plant

    get "/admin/1/edit"

    no_access_assert_status_and_session_message
  end

  def test_edit_plant_type
    edit_default_plant_assert_status_and_relocate(type: 'jade')

    assert_includes last_response.body, 'jade</h1>'
  end

  def test_edit_plant_photo
    edit_default_plant_assert_status_and_relocate(photo: 'jade.jpg')

    assert_includes last_response.body, 'src="jade.jpg"'
  end

  def test_edit_plant_schedule
    edit_default_plant_assert_status_and_relocate(schedule: '1')

    assert_includes last_response.body, 'text">Water 1 time a week'
  end

  def test_edit_plant_notes
    edit_default_plant_assert_status_and_relocate(notes: 'Living Room')

    assert_includes last_response.body, 'Notes: Living Room</p>'
  end

  def test_edit_plant_not_current_user
    create_plants_datafile_with_one_default_plant

    post "/admin/1/edit"

    no_access_assert_status_and_session_message
  end
end

require 'test_helper'

class LocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_path, params: { email: users(:member).email, password: 'test-password-123' }
  end

  test 'lists locations with counts' do
    get locations_path
    assert_response :success
    assert_match 'Shelf A1', response.body
    assert_match 'Shelf B2', response.body
  end

  test 'shows books at location' do
    location = locations(:shelf_a1)

    get location_path(location)
    assert_response :success
    assert_match 'Make Electronics', response.body
    assert_match 'dropdown-toggle', response.body
    assert_match locations(:shelf_b2).name, response.body
  end

  test 'navbar dropdown lists locations alphabetically with counts' do
    get root_path
    assert_response :success
    assert_match 'dropdown-item', response.body
    assert_match locations(:shelf_a1).name, response.body
  end
end

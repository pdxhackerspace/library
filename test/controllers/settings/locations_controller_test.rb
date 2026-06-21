require 'test_helper'

module Settings
  class LocationsControllerTest < ActionDispatch::IntegrationTest
    setup do
      post login_path, params: { email: users(:admin).email, password: 'test-password-123' }
    end

    test 'admin creates location' do
      assert_difference 'Location.count', 1 do
        post settings_locations_path, params: { location: { name: 'Shelf C3' } }
      end

      assert_redirected_to settings_path(anchor: 'locations')
      assert Location.exists?(name: 'Shelf C3')
    end

    test 'admin updates location' do
      location = locations(:shelf_a1)

      patch settings_location_path(location), params: { location: { name: 'Shelf A1 updated' } }

      assert_redirected_to settings_path(anchor: 'locations')
      assert_equal 'Shelf A1 updated', location.reload.name
    end

    test 'admin destroys location' do
      location = locations(:shelf_b2)

      assert_difference 'Location.count', -1 do
        delete settings_location_path(location)
      end

      assert_redirected_to settings_path(anchor: 'locations')
    end
  end
end

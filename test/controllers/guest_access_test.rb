require 'test_helper'

class GuestAccessTest < ActionDispatch::IntegrationTest
  include GuestAccessTestHelper

  test 'off subnet guest cannot view home or books' do
    ENV.delete('GUEST_SUBNET_CIDRS')

    get root_path, env: { 'REMOTE_ADDR' => '203.0.113.10' }
    assert_redirected_to login_path

    get book_path(books(:pragmatic)), env: { 'REMOTE_ADDR' => '203.0.113.10' }
    assert_redirected_to login_path
  end

  test 'on subnet guest can view home and book details' do
    with_guest_subnets('192.168.1.0/24') do
      get_from_ip root_path, '192.168.1.50'
      assert_response :success
      assert_match site_name, response.body
      assert_match 'Recently added', response.body

      get_from_ip book_path(books(:pragmatic)), '192.168.1.50'
      assert_response :success
      assert_match 'The Pragmatic Programmer', response.body
      assert_match 'book-detail', response.body
      assert_match 'book-cover--hero', response.body
      assert_match 'Sign in to check out', response.body
    end
  end

  test 'on subnet guest cannot check out books' do
    with_guest_subnets('192.168.1.0/24') do
      assert_no_difference 'Loan.count' do
        post checkout_book_path(books(:pragmatic)),
             env: { 'REMOTE_ADDR' => '127.0.0.1', 'HTTP_X_FORWARDED_FOR' => '192.168.1.50' }
      end

      assert_redirected_to login_path
    end
  end

  test 'on subnet guest cannot browse authors' do
    with_guest_subnets('192.168.1.0/24') do
      get_from_ip authors_path, '192.168.1.50'
      assert_redirected_to login_path
    end
  end

  test 'logged in user can browse regardless of subnet' do
    ENV.delete('GUEST_SUBNET_CIDRS')
    sign_in_local(users(:member))

    get root_path, env: { 'REMOTE_ADDR' => '203.0.113.10' }
    assert_response :success

    get books_path, env: { 'REMOTE_ADDR' => '203.0.113.10' }
    assert_response :success
    assert_match 'Make Electronics', response.body
  end

  test 'uses forwarded client ip behind trusted proxy' do
    with_guest_subnets('192.168.1.0/24') do
      get_from_ip root_path, '192.168.1.50', proxy: '10.0.0.1'
      assert_response :success
    end
  end

  test 'uses forwarded client ip behind non private trusted proxy' do
    with_guest_subnets('192.168.1.0/24') do
      with_trusted_proxies('172.225.80.225') do
        get_from_ip root_path, '192.168.1.50', proxy: '172.225.80.225'
        assert_response :success
      end
    end
  end

  test 'uses forwarded client ip when trust forwarded headers is enabled' do
    with_guest_subnets('192.168.1.0/24') do
      with_trust_forwarded_headers(true) do
        get_from_ip root_path, '192.168.1.50', proxy: '172.225.80.225'
        assert_response :success
      end
    end
  end

  private

  def site_name
    SiteSetting.instance.site_name
  end
end

require 'rails_helper'

RSpec.describe "Users", type: :request do

  before(:each) do
    Kaminari.config.default_per_page = 5

    @admin = User.create! username: 'admin', password: 'test1234', admin: true
    @user1 = User.create! username: 'john', password: 'test1234'
    @user2 = User.create! username: 'kate', password: 'test1234'

    @admin_headers = {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(
      'admin', 'test1234'
    )}
    @user_headers = {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(
      'john', 'test1234'
    )}
  end

  describe "GET /api/users", focus: false do

    context "for admin" do

      it "returns a list of users" do
        get api_v1_users_path, nil, @admin_headers
        expect( response ).to             have_http_status(200)
        expect( json['status']).to        eq('success')
        expect( json['users'].size).to    eq(3)
        expect( json['page']).to          eq(1)
        expect( json['total_pages']).to   eq(1)
      end

      it "returns only 4 users if total_users_count = 9, per_page = 5, page = 2", focus: false do
        (1 .. 6).each {|n| User.create! username: "user#{n}", password: 'test1234'}

        get api_v1_users_path, {page: 2}, @admin_headers
        expect( response ).to             have_http_status(200)

        expect( json['status']).to        eq('success')
        expect( json['users'].size).to    eq(4)
        expect( json['page']).to          eq(2)
        expect( json['total_pages']).to   eq(2)
      end

    end

    context "for user" do

      it "returns 401 error" do
        get api_v1_users_path, nil, @user_headers
        expect( response ).to           have_http_status(401)
      end

    end

    context "for guest" do
      it "returns 401 error" do
        get api_v1_users_path
        expect( response ).to           have_http_status(401)
      end
    end

  end

  describe "GET /api/users/:id" do

    context "for admin" do

      it "returns a specific user" do
        get api_v1_user_path(@user1), nil, @admin_headers
        expect( response ).to                   have_http_status(200)
        expect( json['status']).to        eq('success')
        expect( json['user'].keys.count ).to    eq(2)
        expect( json['user']['username'] ).to   eq('john')
      end

      it "returns 401 error if user doesn't exist" do
        get api_v1_user_path(9999), nil, @admin_headers
        expect( response ).to                   have_http_status(401)
      end

    end

    context "for user" do

      it "returns a specific user for user himself" do
        get api_v1_user_path(@user1), nil, @user_headers
        expect( response ).to                   have_http_status(200)
        expect( json['status']).to        eq('success')
        expect( json['user'].keys.count ).to    eq(2)
        expect( json['user']['username'] ).to eq('john')
      end

      it "returns 401 error for another user" do
        get api_v1_user_path(@user2), nil, @user_headers
        expect( response ).to                   have_http_status(401)
      end

      it "returns 401 error if user doesn't exist" do
        get api_v1_user_path(9999), nil, @user_headers
        expect( response ).to                   have_http_status(401)
      end

    end

    context "for guest" do

      it "returns 401 error" do
        get api_v1_user_path(@user2), nil
        expect( response ).to                   have_http_status(401)
      end      

    end

  end



  describe "POST /api/users" do

    context "for admin" do

      it "creates a correct new user" do
        post api_v1_users_path, { user: { username: 'mannie', password: 'test1234' } }, @admin_headers
        expect( response ).to                   have_http_status(200)
        expect( json['status']).to              eq('success')
        expect( json['user'].keys.count ).to    eq(2)
        expect( json['user']['username'] ).to   eq('mannie')
      end

      it "returns errors if username isn't unique" do
        post api_v1_users_path, { user: { username: 'john', password: 'test1234' } }, @admin_headers
        expect( response ).to                           have_http_status(400)
        expect( json['status']).to                      eq('failed')
        expect( json['user']['errors'].keys.count ).to  eq(1)
        expect( json['user']['errors']['username'] ).to match_array("has already been taken")
      end

      it "returns errors if username is empty" do
        post api_v1_users_path, { user: { password: 'test1234' } }, @admin_headers
        expect( response ).to                           have_http_status(400)
        expect( json['status']).to                      eq('failed')
        expect( json['user']['errors'].keys.count ).to  eq(1)
        expect( json['user']['errors']['username'] ).to match_array(["can't be blank"])
      end

      it "returns errors if password is empty" do
        post api_v1_users_path, { user: { username: 'mannie' } }, @admin_headers
        expect( response ).to                           have_http_status(400)
        expect( json['status']).to                      eq('failed')
        expect( json['user']['errors'].keys.count ).to  eq(1)
        expect( json['user']['errors']['password'] ).to match_array(["can't be blank"])
      end

    end

    context "for user" do

      it "creates a correct new user" do
        post api_v1_users_path, { user: { username: 'mannie', password: 'test1234' } }, @user_headers
        expect( response ).to                           have_http_status(200)
        expect( json['status']).to                      eq('success')
        expect( json['user'].keys.count ).to            eq(2)
        expect( json['user']['username'] ).to           eq('mannie')
      end

    end

    context "for guest" do

      it "creates a correct new user" do
        post api_v1_users_path, { user: { username: 'mannie', password: 'test1234' } }
        expect( response ).to                           have_http_status(200)
        expect( json['status']).to                      eq('success')
        expect( json['user'].keys.count ).to            eq(2)
        expect( json['user']['username'] ).to           eq('mannie')
      end      

    end

  end


  describe "PUT /api/users" do

    context "for admin" do

      it "updates an existing user" do
        put api_v1_user_path(@user1), { user: { username: 'mannie', password: 'test12345' } }, @admin_headers
        expect( response ).to                           have_http_status(200)
        expect( json['status']).to                      eq('success')
        expect( json['user'].keys.count ).to            eq(2)
        expect( json['user']['username'] ).to           eq('mannie')
      end

      it "returns 401 error if user doesn't exist" do
        put api_v1_user_path(9999), { user: { username: 'mannie', password: 'test12345' } }, @admin_headers
        expect( response ).to                 have_http_status(401)
      end

      it "returns errors if username isn't unique" do
        user2 = User.create! username: 'mannie', password: 'test1234'
        put api_v1_user_path(@user1), { user: { username: 'mannie', password: 'test12345' } }, @admin_headers
        expect( response ).to                           have_http_status(400)
        expect( json['status']).to                      eq('failed')
        expect( json['user']['errors'].keys.count ).to  eq(1)
        expect( json['user']['errors']['username'] ).to match_array(["has already been taken"])
      end

    end

    context "for user" do

      it "updates an existing user himself" do
        put api_v1_user_path(@user1), { user: { username: 'mannie', password: 'test12345' } }, @user_headers
        expect( response ).to                           have_http_status(200)
        expect( json['status']).to                      eq('success')
        expect( json['user'].keys.count ).to            eq(2)
        expect( json['user']['username'] ).to           eq('mannie')
      end

      it "returns 401 error for another user" do
        put api_v1_user_path(@user2), { user: { username: 'mannie', password: 'test12345' } }, @user_headers
        expect( response ).to                           have_http_status(401)
      end

    end

    context "for guest" do

      it "returns 401 error" do
        put api_v1_user_path(@user2), { user: { username: 'mannie', password: 'test12345' } }
        expect( response ).to                           have_http_status(401)
      end      

    end

  end


  describe "DELETE /api/users/:id" do

    context "for admin" do

      it "destroys an existing user" do
        delete api_v1_user_path(@user1), nil, @admin_headers
        expect( response ).to                           have_http_status(200)
        expect( json['status']).to                      eq('success')
      end

      it "returns 401 error if user doesn't exist" do
        delete api_v1_user_path(9999), nil, @admin_headers
        expect( response ).to                           have_http_status(401)
      end

    end

    context "for user" do

      it "destroys an existing user himself" do
        delete api_v1_user_path(@user1), nil, @user_headers
        expect( response ).to                           have_http_status(200)
        expect( json['status']).to                      eq('success')
      end
      
      it "returns 401 error for another user" do
        delete api_v1_user_path(@user2), nil, @user_headers
        expect( response ).to                           have_http_status(401)
      end

    end

    context "for guest" do

      it "returns 401 error" do
        delete api_v1_user_path(@user2)
        expect( response ).to                           have_http_status(401)
      end      

    end

  end

end
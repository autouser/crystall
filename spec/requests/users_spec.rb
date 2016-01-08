require 'rails_helper'

RSpec.describe "Users", type: :request do

  let(:admin_headers) {
    { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'test1234') }
  }

  let(:user_headers) {
    { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('john', 'test1234') }
  }

  let(:user)                  { create :user  }
  let(:admin)                 { create :admin }

  def expect_successfull_list_response(args={})
    args = {page: 1, total_pages: 1, count: 1}.merge args
    expect( response ).to               have_http_status(200)
    expect( json['status']).to          eq('success')
    expect( json['users'].size).to   eq( args[:count] )
    expect( json['page']).to            eq( args[:page] )
    expect( json['total_pages']).to     eq( args[:total_pages] )
  end

  describe "GET /api/users", focus: false do
    context "when user is admin" do
      context "when there is a count of users less than per_page" do
        it "returns a list of users" do
          admin; user
          get api_v1_users_path, nil, admin_headers
          expect_successfull_list_response count: 2
        end
      end

      context "when there are 7 users and per_page = 5 and page = 2" do
        let(:user_projects_count) { 7 }
        it "returns only 2 users" do
          Kaminari.config.default_per_page = 5
          admin; user
          5.times {|n| create :user, username: "user#{n+1}"}

          get api_v1_users_path, {page: 2}, admin_headers
          expect_successfull_list_response count: 2, page: 2, total_pages: 2
        end
      end
    end

    context "when user is user" do
      it "returns 401 error" do
        get api_v1_users_path, nil, user_headers
        expect( response ).to           have_http_status(401)
      end
    end

    context "when user is guest" do
      it "returns 401 error" do
        get api_v1_users_path
        expect( response ).to           have_http_status(401)
      end
    end

  end

  def expect_successfull_entry_response(user)
    expect( response ).to                     have_http_status(200)
    expect( json['status']).to                eq('success')
    expect( json['user'].keys.count ).to      eq(2)
    expect( json['user']['username'] ).to     eq(user.username)
  end


  describe "GET /api/users/:id" do
    context "when user is admin" do
      context "when user exists" do
        it "returns a specific user" do
          admin; user
          get api_v1_user_path(user), nil, admin_headers
          expect_successfull_entry_response(user)
        end
      end

      context "when user doesn't exist" do
        it "returns 404 error" do
          admin
          get api_v1_user_path(9999), nil, admin_headers
          expect( response ).to            have_http_status(404)
        end
      end
    end

    context "when user is user" do
      context "when user is owner of account" do
        it "returns a specific user" do
          user
          get api_v1_user_path(user), nil, user_headers
          expect_successfull_entry_response(user)
        end
      end

      context "when user isn't owner of account" do
        it "returns 401 error" do
          admin; user
          get api_v1_user_path(admin), nil, user_headers
          expect( response ).to            have_http_status(401)
        end
      end
    end

    context "when user is guest" do
      it "returns 401 error" do
        user
        get api_v1_user_path(user)
        expect( response ).to              have_http_status(401)
      end
    end

  end

  def expect_failed_field(field, error)
    expect( response ).to                           have_http_status(400)
    expect( json['status']).to                      eq('failed')
    expect( json['user']['errors'].keys.count ).to  eq(1)
    expect( json['user']['errors'][field] ).to match_array([error])
  end

  RSpec.shared_context "a create response" do |headers, ns|

    before(:each) { send(ns) }

    context "when arguments are correct" do
      it "creates a new user" do
        post api_v1_users_path, { user: { username: 'mannie', password: 'test1234' } }, (headers ? send(headers) : nil)
        expect_successfull_entry_response( User.find_by(username: 'mannie') )
      end
    end

    context "when username is empty" do
      it "returns an error" do
        post api_v1_users_path, { user: { password: 'test1234' } }, (headers ? send(headers) : nil)
        expect_failed_field('username', "can't be blank")
      end
    end

    context "when username isn't unique" do
      it "returns an error" do
        create :user, username: "mannie"
        post api_v1_users_path, { user: { username: 'mannie', password: 'test1234' } }, (headers ? send(headers) : nil)
        expect_failed_field('username', "has already been taken")
      end
    end

    context "when password is empty" do
      it "returns an error" do
        post api_v1_users_path, { user: { username: 'mannie' } }, (headers ? send(headers) : nil)
        expect_failed_field('password', "can't be blank")
      end
    end

  end

  describe "POST /api/users" do
    context "when user is admin" do
      it_behaves_like "a create response", :admin_headers, :admin
    end

    context "when user is user" do
      it_behaves_like "a create response", :user_headers, :user
    end

    context "when user is guest" do
      it_behaves_like "a create response", nil, :user
    end
  end

  RSpec.shared_context "an update response" do |headers, ns|

    before(:each) { send(ns) }

    context "when user is owned" do
      it "updates it's own account" do
        admin
        put api_v1_user_path( send(ns) ), { user: { username: 'mannie', password: 'test12345' } }, (headers ? send(headers) : nil)
        expect_successfull_entry_response(User.find_by(username: 'mannie'))
      end
    end

    context "when user doesn't exist" do
      it "returns 404 error" do
        put api_v1_user_path( 9999 ), { user: { username: 'mannie', password: 'test12345' } }, (headers ? send(headers) : nil)
        expect( response ).to have_http_status(404)
      end
    end

    context "when username isn't unique" do
      it "returns an error" do
        create :user, username: "mannie"
        put api_v1_user_path( send(ns) ), { user: { username: 'mannie', password: 'test12345' } }, (headers ? send(headers) : nil)
        expect_failed_field('username', "has already been taken")
      end
    end

    context "when username is empty" do
      it "returns an error" do
        put api_v1_user_path( send(ns) ), { user: { username: '', password: 'test12345' } }, (headers ? send(headers) : nil)
        expect_failed_field('username', "can't be blank")
      end
    end

  end


  describe "PUT /api/users" do

    context "when user is admin" do
      it_behaves_like "an update response", :admin_headers, :admin

      context "when user isn't owned" do
        it "updates user" do
          admin; user
          put api_v1_user_path( user ), { user: { username: 'mannie', password: 'test12345' } }, admin_headers
          expect_successfull_entry_response(User.find_by(username: 'mannie'))
        end
      end

    end

    context "when user is user" do
      it_behaves_like "an update response", :user_headers, :user

      context "when user isn't owned" do
        it "returns 401 error" do
          admin; user
          get api_v1_user_path(admin)
          expect( response ).to              have_http_status(401)
        end
      end
    end

    context "when user is guest" do
      it "returns 401 error" do
        user
        get api_v1_user_path(user)
        expect( response ).to              have_http_status(401)
      end
    end

  end


  RSpec.shared_context "a delete response" do |headers, ns|

    context "when user exists" do
      it "destroys it's own account" do
        delete api_v1_user_path( send(ns) ), nil, (headers ? send(headers) : nil)
        expect( response ).to                           have_http_status(200)
        expect( json['status']).to                      eq('success')
      end        
    end

    context "when user doesn't exist" do
      it "returns 404 error" do
        delete api_v1_user_path( 9999 ), nil, (headers ? send(headers) : nil)
        expect( response ).to                           have_http_status(404)
      end
    end
  end

  fdescribe "DELETE /api/users/:id" do
    context "when user is admin" do
      it_behaves_like "a delete response", :admin_headers, :admin


      context "when user isn't owned" do
        it "destroys it" do
          admin; user
          delete api_v1_user_path( user ), nil, admin_headers
          expect( response ).to                           have_http_status(200)
          expect( json['status']).to                      eq('success')
        end
      end
    end

    context "when user is user" do
      it_behaves_like "a delete response", :user_headers, :user

      context "when user isn't owned" do
        it "returns 401 error" do
          admin; user
          delete api_v1_user_path( admin ), nil, user_headers
          expect( response ).to              have_http_status(401)
        end
      end
    end

    context "when user is guest" do
      it "returns 401 error" do
        admin
        delete api_v1_user_path( admin )
        expect( response ).to              have_http_status(401)
      end
    end

  end

  # describe "DELETE /api/users/:id" do

  #   context "for admin" do

  #     it "destroys an existing user" do
  #       delete api_v1_user_path(@user1), nil, @admin_headers
  #       expect( response ).to                           have_http_status(200)
  #       expect( json['status']).to                      eq('success')
  #     end

  #     it "returns 401 error if user doesn't exist" do
  #       delete api_v1_user_path(9999), nil, @admin_headers
  #       expect( response ).to                           have_http_status(401)
  #     end

  #   end

  #   context "for user" do

  #     it "destroys an existing user himself" do
  #       delete api_v1_user_path(@user1), nil, @user_headers
  #       expect( response ).to                           have_http_status(200)
  #       expect( json['status']).to                      eq('success')
  #     end
      
  #     it "returns 401 error for another user" do
  #       delete api_v1_user_path(@user2), nil, @user_headers
  #       expect( response ).to                           have_http_status(401)
  #     end

  #   end

  #   context "for guest" do

  #     it "returns 401 error" do
  #       delete api_v1_user_path(@user2)
  #       expect( response ).to                           have_http_status(401)
  #     end      

  #   end

  # end

end
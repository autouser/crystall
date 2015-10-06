require 'rails_helper'

RSpec.describe "Projects", type: :request do

  before(:each) do

    Kaminari.config.default_per_page = 5

    @admin = User.create! username: 'admin', password: 'test1234', admin: true
    @user = User.create! username: 'john', password: 'test1234'

    @admin_headers = {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(
      'admin', 'test1234'
    )}
    @user_headers = {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(
      'john', 'test1234'
    )}

    @admin_project = @admin.projects.create!  name: 'Core 1.0', description: 'Core System', status: 'open'
    @user_project  = @user.projects.create!   name: 'Core 2.0', description: 'Core System (development)', status: 'closed'

  end

  def expect_failed_field(field, error)
    expect( response ).to                           have_http_status(400)
    expect( json['status']).to                      eq('failed')
    expect( json['project']['errors'].keys.count ).to  eq(1)
    expect( json['project']['errors'][field] ).to match_array([error])

  end

  describe "GET /api/projects", focus: false do

    def expect_successfull_response
      expect( response ).to               have_http_status(200)
      expect( json['status']).to          eq('success')
      expect( json['projects'].size).to   eq(2)
      expect( json['page']).to            eq(1)
      expect( json['total_pages']).to     eq(1)
    end

    context "for admin" do

      it "returns a list of projects" do
        get api_v1_projects_path, nil, @admin_headers
        expect_successfull_response
      end

      it "returns only 4 projects if total_projects_count = 9, per_page = 5, page = 2", focus: false do
        (1 .. 7).each {|n| Project.create! user: @admin, name: "project#{n}", status: 'open'}

        get api_v1_projects_path, {page: 2}, @admin_headers
        expect( response ).to               have_http_status(200)
        expect( json['status']).to          eq('success')
        expect( json['projects'].size).to   eq(4)
        expect( json['page']).to            eq(2)
        expect( json['total_pages']).to     eq(2)
      end

    end

    context "for user" do

      it "returns a list of projects" do
        get api_v1_projects_path, nil, @user_headers
        expect_successfull_response
      end      

    end

    context "for guest" do

      it "returns a list of projects" do
        get api_v1_projects_path
        expect_successfull_response
      end      

    end

  end


  describe "GET /api/projects/:id" do

    def expect_successfull_response
        expect( response ).to                     have_http_status(200)
        expect( json['status']).to                eq('success')
        expect( json['project'].keys.count ).to   eq(5)
        expect( json['project']['name'] ).to      eq('Core 1.0')
        expect( json['project']['owner'] ).to     eq(@admin.username)      
    end

    context "for admin" do

      it "returns a specific project" do
        get api_v1_project_path(@admin_project), nil, @admin_headers
        expect_successfull_response
      end

      it "returns 401 error if project doesn't exist" do
        get api_v1_user_path(9999), nil, @admin_headers
        expect( response ).to have_http_status(401)
      end

    end

    context "for user" do

      it "returns a specific project" do
        get api_v1_project_path(@admin_project), nil, @user_headers
        expect_successfull_response
      end

      it "returns 401 error if project doesn't exist" do
        get api_v1_user_path(9999), nil, @user_headers
        expect( response ).to have_http_status(401)
      end

    end

    context "for guest" do

      it "returns a specific project" do
        get api_v1_project_path(@admin_project)
        expect_successfull_response
      end

      it "returns 401 error if project doesn't exist" do
        get api_v1_user_path(9999)
        expect( response ).to have_http_status(401)
      end

    end

  end


  describe "POST /api/projects" do

    def expect_successfull_creation(owner)
      expect( response ).to                         have_http_status(200)
      expect( json['status']).to                    eq('success')
      expect( json['project'].keys.count ).to       eq(5)
      expect( json['project']['name'] ).to          eq('Core 3.0')
      expect( json['project']['description'] ).to   eq('Core (planed)')
      expect( json['project']['owner'] ).to         eq(owner)      
    end

    context "for admin" do

      it "creates a correct new project" do
        post( api_v1_projects_path, {
          project: {
            name: 'Core 3.0',
            description: 'Core (planed)',
            status: "closed"
          }
        }, @admin_headers)
        expect_successfull_creation('admin')
      end

      it "returns errors if name is empty" do
        post( api_v1_projects_path, {
          project: {
            description: 'Core (planed)',
            status: "closed"
          }
        }, @admin_headers)
        expect_failed_field('name', "can't be blank")
      end

      it "returns errors if name isn't unique" do
        post( api_v1_projects_path, {
          project: {
            name: 'Core 2.0',
            description: 'Core (planed)',
            status: "closed"
          }
        }, @admin_headers)
        expect_failed_field('name', "has already been taken")
      end

      it "returns errors if status ist valid" do
        post( api_v1_projects_path, {
          project: {
            name: 'Core 3.0',
            description: 'Core (planed)',
            status: "wrong"
          }
        }, @admin_headers)
        expect_failed_field('status', "is not included in the list")
      end


    end

    context "for user" do

      it "creates a correct new project" do
        post( api_v1_projects_path, {
          project: {
            name: 'Core 3.0',
            description: 'Core (planed)',
            status: "closed"
          }
        }, @user_headers)
        expect_successfull_creation('john')
      end

    end

    context "for guest" do

      it "creates a correct new project" do
        post( api_v1_projects_path, {
          project: {
            name: 'Core 3.0',
            description: 'Core (planed)',
            status: "closed"
          }
        })
        expect( response ).to  have_http_status(401)
      end

    end

  end



  describe "PUT /api/project/:id", focus: true do

    def expect_successfull_update
      expect( response ).to                           have_http_status(200)
      expect( json['status']).to                      eq('success')
      expect( json['project'].keys.count ).to         eq(5)
      expect( json['project']['name'] ).to            eq('Core 2.0 (drop)')
      expect( json['project']['description'] ).to     eq('Core (drop)')
      expect( json['project']['status'] ).to          eq('closed')
      expect( json['project']['owner'] ).to           eq('john')
    end

    context "for admin" do

      it "updates any existing project" do
        put( api_v1_project_path(@user_project), {
          project: {
            name: 'Core 2.0 (drop)',
            description: 'Core (drop)',
            status: "closed"
          }
        }, @admin_headers )
        expect_successfull_update
      end

      it "returns 401 error if project doesn't exist" do
        put( api_v1_project_path(9999), {
          project: {
            name: 'Core 2.0 (drop)',
            description: 'Core (drop)',
            status: "closed"
          }
        }, @admin_headers )
        expect( response ).to have_http_status(401)
      end

      it "returns errors if name isn't unique" do
        put( api_v1_project_path(@user_project), {
          project: {
            name: 'Core 1.0',
            description: 'Core (drop)',
            status: "closed"
          }
        }, @admin_headers )
        expect_failed_field('name', "has already been taken")
      end

      it "returns errors if name is empty" do
        put( api_v1_project_path(@user_project), {
          project: {
            name: '',
            description: 'Core (drop)',
            status: "closed"
          }
        }, @admin_headers )
        expect_failed_field('name', "can't be blank")
      end

      it "returns errors if status is valid" do
        put( api_v1_project_path(@user_project), {
          project: {
            name: 'Core 3.0',
            description: 'Core (planed)',
            status: "wrong"
          }
        }, @admin_headers)
        expect_failed_field('status', "is not included in the list")
      end

    end

    context "for user" do

      it "updates owned project" do
        put( api_v1_project_path(@user_project), {
          project: {
            name: 'Core 2.0 (drop)',
            description: 'Core (drop)',
            status: "closed"
          }
        }, @user_headers )
        expect_successfull_update
      end

      it "returns 401 error for not owned project" do
        put( api_v1_project_path(@admin_project), {
          project: {
            name: 'Core 2.0 (drop)',
            description: 'Core (drop)',
            status: "closed"
          }
        }, @user_headers )
        
        expect( response.status ).to eq(401)
      end

      it "returns 401 error if project doesn't exist" do
        put( api_v1_project_path(9999), {
          project: {
            name: 'Core 2.0 (drop)',
            description: 'Core (drop)',
            status: "closed"
          }
        }, @user_headers )
        expect( response ).to have_http_status(401)
      end

    end


    context "for guest" do

      it "returns 401 error for any project" do
        put( api_v1_project_path(@admin_project), {
          project: {
            name: 'Core 2.0 (drop)',
            description: 'Core (drop)',
            status: "closed"
          }
        } )
        
        expect( response.status ).to eq(401)
      end

    end

  end

  describe "DELETE /api/project/:id" do

    context "for admin" do

      it "destroys an existing project" do
        delete api_v1_project_path(@user_project), nil, @admin_headers
        expect( response ).to                           have_http_status(200)
        expect( json['status']).to                      eq('success')
      end

      it "returns 401 error if project doesn't exist" do
        delete api_v1_project_path(9999), nil, @admin_headers
        expect( response ).to                           have_http_status(401)
      end

    end

    context "for user" do

      it "destroys an owned project" do
        delete api_v1_project_path(@user_project), nil, @user_headers
        expect( response ).to                           have_http_status(200)
        expect( json['status']).to                      eq('success')
      end

      it "returns 401 error for not owned project" do
        delete api_v1_project_path(@admin_project), nil, @user_headers
        expect( response ).to have_http_status(401)
      end

      it "returns 401 error if project doesn't exist" do
        delete api_v1_project_path(9999), nil, @user_headers
        expect( response ).to have_http_status(401)
      end

    end

    context "for guest" do

      it "returns 401 error for any project" do
        delete api_v1_project_path(@admin_project)
        expect( response ).to have_http_status(401)
      end

    end


  end


end

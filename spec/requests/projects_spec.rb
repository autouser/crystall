require 'rails_helper'

RSpec.describe "Projects", type: :request do

  let(:admin_headers) {
    { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'test1234') }
  }

  let(:user_headers) {
    { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('john', 'test1234') }
  }

  let(:user)                  { create :user  }
  let(:admin)                 { create :admin }

  let(:user_projects_count)   { 2 }
  let(:user_projects)         { user_projects_count.times {|n| create :project, name: "User Project #{n+1}", user: user } }

  let(:admin_projects_count)  { 2 }
  let(:admin_projects)        { admin_projects_count.times {|n| create :project, name: "Admin Project #{n+1}", user: admin } }

  let(:user_project)          { create :project, name: "User Project 1", user: user }
  let(:admin_project)         { create :project, name: "Admin Project 1", user: admin }

  def expect_successfull_list_response(args={})
    args = {page: 1, total_pages: 1, count: 1}.merge args
    expect( response ).to               have_http_status(200)
    expect( json['status']).to          eq('success')
    expect( json['projects'].size).to   eq( args[:count] )
    expect( json['page']).to            eq( args[:page] )
    expect( json['total_pages']).to     eq( args[:total_pages] )
  end

  describe "GET /api/projects" do

    RSpec.shared_context "a projects list response" do |headers|

      context "when there are count of projects less than per_page" do
        it "returns a list of projects" do
          user_projects
          admin_projects
          get api_v1_projects_path, nil, headers ? send(headers) : nil
          expect_successfull_list_response count: 4
        end
      end

      context "when there are 7 projects and per_page = 5 and page = 2" do
        let(:user_projects_count) { 7 }
        it "returns only 2 projects" do
          Kaminari.config.default_per_page = 5
          user_projects
          get api_v1_projects_path, {page: 2}, headers ? send(headers) : nil
          expect_successfull_list_response count: 2, page: 2, total_pages: 2
        end
      end

    end

    context "when user is admin" do
      it_behaves_like "a projects list response", :admin_headers
    end

    context "when user is user" do
      it_behaves_like "a projects list response", :user_headers
    end

    context "when user is guest" do
      it_behaves_like "a projects list response"
    end

  end


  describe "GET /api/projects/mine" do

    let(:user_projects_count)   { 2 }
    let(:admin_projects_count)  { 3 }
    context "when user is authenticated" do
      it "returns a list of user owned projects" do
        user_projects
        admin_projects
        get mine_api_v1_projects_path, nil, user_headers
        expect_successfull_list_response count: 2
      end
    end
    context "when user isn't authenticated" do
      it "returns 401 error" do
        user_projects
        get mine_api_v1_projects_path
        expect( response ).to                 have_http_status(401)
      end
    end
  end


  def expect_successfull_entry_response(project)
    expect( response ).to                     have_http_status(200)
    expect( json['status']).to                eq('success')
    expect( json['project'].keys.count ).to   eq(5)
    expect( json['project']['name'] ).to      eq(project.name)
    expect( json['project']['owner'] ).to     eq(project.user.username)
  end

  RSpec.shared_context "a project entry response" do |headers|
    context "when project exists" do
      it "returns a specific project" do
        get api_v1_project_path( admin_project ), nil, headers ? send(headers) : nil
        expect_successfull_entry_response( admin_project )
      end
    end
    context "when project doesn't exist" do
      it "returns 404 error" do
        get api_v1_project_path(9999), nil, headers ? send(headers) : nil
        expect( response ).to have_http_status(404)
      end
    end    
  end

  describe "GET /api/projects/:id" do

    context "when user is admin" do
      it_behaves_like "a project entry response", :admin_headers
    end

    context "when user is user" do
      it_behaves_like "a project entry response", :user_headers
    end

    context "when user is guest" do
      it_behaves_like "a project entry response"
    end

  end

  def expect_failed_field(field, error)
    expect( response ).to                           have_http_status(400)
    expect( json['status']).to                      eq('failed')
    expect( json['project']['errors'].keys.count ).to  eq(1)
    expect( json['project']['errors'][field] ).to match_array([error])
  end

  def build_params(args={})
    merged = { name: 'Project 1', description: 'Project Description', status: "closed" }.merge args
    {project: merged }
  end

  RSpec.shared_context "a create project response" do |headers, ns|
    before(:each) { send(ns) }

    context "when arguments are correct" do
      it "creates a new project" do
        post( api_v1_projects_path, build_params,  (headers ? send(headers) : nil))
        expect_successfull_entry_response( send(ns).projects.find_by(name: 'Project 1') )
      end
    end

    context "when name is empty" do
      it "returns an error" do
        post( api_v1_projects_path, build_params(name: nil), (headers ? send(headers) : nil))
        expect_failed_field('name', "can't be blank")
      end
    end

    context "when name isn't unique" do
      it "returns an error" do
        create :project, name: "Project 1", user: send(ns)
        post( api_v1_projects_path, build_params, (headers ? send(headers) : nil))
        expect_failed_field('name', "has already been taken")
      end
    end

    context "when status isn't valid" do
      it "returns an error" do
        post( api_v1_projects_path, build_params(status: 'wrong'), (headers ? send(headers) : nil))
        expect_failed_field('status', "is not included in the list")
      end
    end
  end

  describe "POST /api/projects" do

    context "when user is admin" do
      it_behaves_like "a create project response", :admin_headers, :admin
    end

    context "when user is user" do
      it_behaves_like "a create project response", :user_headers, :user
    end

    context "when user is guest" do
      it "returns 401 error" do
        post( api_v1_projects_path, build_params)
        expect( response ).to  have_http_status(401)
      end
    end

  end


  describe "PUT /api/project/:id" do

    RSpec.shared_context "an update project response" do |headers, ns, existing_project|
      context "when project is owned" do
        it "updates any existing project" do
          put( api_v1_project_path(send(existing_project)), build_params(name: 'Project 1.1', description: 'Description 1.1', status: 'open'), (headers ? send(headers) : nil) )
          expect_successfull_entry_response( send(ns).projects.find_by(name: 'Project 1.1') )
        end
      end

      context "when project doesn't exist" do
        it "returns 404 error" do
          put( api_v1_project_path(9999), build_params, (headers ? send(headers) : nil) )
          expect( response ).to have_http_status(404)
        end
      end

      context "when name isn't unique" do
        it "returns an error" do
          create :project, name: "Project 1.1", user: send(ns)
          put( api_v1_project_path( send(existing_project) ), build_params(name: 'Project 1.1'), (headers ? send(headers) : nil))
          expect_failed_field('name', "has already been taken")
        end
      end

      context "when name is empty" do
        it "returns an error" do
          put( api_v1_project_path( send(existing_project) ), build_params(name: ''), (headers ? send(headers) : nil))
          expect_failed_field('name', "can't be blank")
        end
      end

      context "when status is invalid" do
        it "returns an error" do
          put( api_v1_project_path( send(existing_project) ), build_params(status: 'wrong'), (headers ? send(headers) : nil))
          expect_failed_field('status', "is not included in the list")
        end
      end
    end

    context "when user is admin" do
      it_behaves_like "an update project response", :admin_headers, :admin, :admin_project

      context "when a project isn't owned" do
        it "returns 401 error" do
          admin_project
          user_project
          put( api_v1_project_path( admin_project ), build_params, user_headers )
          expect( response ).to  have_http_status(401)
        end        
      end
    end

    context "when user is user" do
      it_behaves_like "an update project response", :user_headers, :user, :user_project

      context "when a project isn't owned" do
        it "returns 401 error" do
          admin_project
          user_project
          put( api_v1_project_path( admin_project ), build_params, user_headers )
          expect( response ).to  have_http_status(401)
        end        
      end
    end

    context "when user is guest" do
      it "returns 401 error" do
        put( api_v1_project_path( user_project ), build_params )
        expect( response ).to  have_http_status(401)
      end
    end

  end



  describe "DELETE /api/project/:id" do

    RSpec.shared_context "a delete project response" do |headers, ns, existing_project|
      context "when project is owned" do
        it "destroys it" do
          delete api_v1_project_path(send(existing_project)), nil, (headers ? send(headers) : nil)
          expect( response ).to                           have_http_status(200)
          expect( json['status']).to                      eq('success')
        end        
      end

      context "when project doesn't exist" do
        it "returns 404 error" do
          delete api_v1_project_path(9999), nil, (headers ? send(headers) : nil)
          expect( response ).to                           have_http_status(404)
        end
      end

    end

    context "when user is admin" do
      it_behaves_like "a delete project response", :admin_headers, :admin, :admin_project
    end

    context "when user is user" do
      it_behaves_like "a delete project response", :user_headers, :user, :user_project
    end

    context "when user is guest" do
      it "returns 401 error" do
        delete api_v1_project_path(admin_project)
        expect( response ).to  have_http_status(401)
      end
    end

  end

end

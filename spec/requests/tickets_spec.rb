require 'rails_helper'

RSpec.describe "Tickets", type: :request do

  before(:each) do
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

    @ticket1 = @admin_project.tickets.create! user: @admin, subject: 'broken', content: 'completely'
    @ticket2 = @admin_project.tickets.create! user: @user,  subject: 'still broken', content: 'completely'
    @ticket3 = @user_project.tickets.create!  user: @user,  subject: 'broken', content: 'completely'

  end

  def expect_failed_field(field, error)
    expect( response ).to                           have_http_status(400)
    expect( json['status']).to                      eq('failed')
    expect( json['ticket']['errors'].keys.count ).to  eq(1)
    expect( json['ticket']['errors'][field] ).to match_array([error])
  end


  describe "GET /api/tickets", focus: false do

    def expect_successfull_response
      expect( response ).to               have_http_status(200)
      expect( json['status']).to          eq('success')
      expect( json['tickets'].size).to   eq(2)
    end

    context "for admin" do
      it "returns a list of tickets" do
        get api_v1_project_tickets_path(@admin_project), nil, @admin_headers
        expect_successfull_response
      end
    end

    context "for user" do
      it "returns a list of tickets" do
        get api_v1_project_tickets_path(@admin_project), nil, @user_headers
        expect_successfull_response
      end
    end

  end


  describe "GET /api/tickets/:id" do

    def expect_successfull_response
        expect( response ).to                           have_http_status(200)
        expect( json['status']).to                      eq('success')
        expect( json['ticket'].keys.count ).to          eq(6)
        expect( json['ticket']['subject'] ).to          eq('broken')
        expect( json['ticket']['content'] ).to          eq('completely')
        expect( json['ticket']['status'] ).to           eq('open')
        expect( json['ticket']['owner'] ).to            eq(@admin.username)  
        expect( json['ticket']['project']['id'] ).to    eq(@admin_project.id)
        expect( json['ticket']['project']['name'] ).to  eq(@admin_project.name)
    end

    context "for admin" do

      it "returns a specific ticket" do
        get api_v1_project_ticket_path(@admin_project, @ticket1), nil, @admin_headers
        expect_successfull_response
      end

      it "returns 401 error if tickey doesn't exist" do
        get api_v1_project_ticket_path(@admin_project, 9999), nil, @admin_headers
        expect( response ).to have_http_status(401)
      end

    end

    context "for user" do

      it "returns a specific ticket" do
        get api_v1_project_ticket_path(@admin_project, @ticket1), nil, @user_headers
        expect_successfull_response
      end

      it "returns 401 error if ticket doesn't exist" do
        get api_v1_project_ticket_path(@admin_project, 9999), nil, @user_headers
        expect( response ).to have_http_status(401)
      end

    end

    context "for guest" do

      it "returns a specific ticket" do
        get api_v1_project_ticket_path(@admin_project, @ticket1)
        expect_successfull_response
      end

      it "returns 401 error if ticket doesn't exist" do
        get api_v1_project_ticket_path(@admin_project, 9999)
        expect( response ).to have_http_status(401)
      end

    end

  end


  describe "POST /api/tickets" do

    def expect_successfull_creation(project, owner)
      expect( response ).to                         have_http_status(200)
      expect( json['status']).to                      eq('success')
      expect( json['ticket'].keys.count ).to          eq(6)
      expect( json['ticket']['subject'] ).to          eq('broken too much')
      expect( json['ticket']['content'] ).to          eq('completely...')
      expect( json['ticket']['status'] ).to           eq('closed')
      expect( json['ticket']['owner'] ).to            eq(owner.username)  
      expect( json['ticket']['project']['id'] ).to    eq(project.id)
      expect( json['ticket']['project']['name'] ).to  eq(project.name)
    end

    context "for admin" do

      it "creates a correct new ticket" do
        post( api_v1_project_tickets_path(@admin_project), {
          ticket: {
            subject:  'broken too much',
            content:  'completely...',
            status:   'closed'
          }
        }, @admin_headers)
        expect_successfull_creation(@admin_project,@admin)
      end

      it "returns errors if name is empty" do
        post( api_v1_project_tickets_path(@admin_project), {
          ticket: {
            subject:  'broken too much',
            status:   'closed'
          }
        }, @admin_headers)
        expect_failed_field('content', "can't be blank")
      end

      it "returns errors if status is wrong" do
        post( api_v1_project_tickets_path(@admin_project), {
          ticket: {
            subject:  'broken too much',
            content:  'completely...',
            status:   'wrong'
          }
        }, @admin_headers)
        expect_failed_field('status', "is not included in the list")
      end

    end

    context "for user" do

      it "creates a correct new ticket" do
        post( api_v1_project_tickets_path(@user_project), {
          ticket: {
            subject:  'broken too much',
            content:  'completely...',
            status:   'closed'
          }
        }, @user_headers)
        expect_successfull_creation(@user_project, @user)
      end

      it "creates a correct new ticket if project is owned and closed" do
        @user_project.update status: 'closed'
        post( api_v1_project_tickets_path(@user_project), {
          ticket: {
            subject:  'broken too much',
            content:  'completely...',
            status:   'closed'
          }
        }, @user_headers)
        expect_successfull_creation(@user_project, @user)
      end

      it "returns errors if project isn't owned and closed" do
        @admin_project.update status: 'closed'
        post( api_v1_project_tickets_path(@admin_project), {
          ticket: {
            subject:  'broken too much',
            content:  'completely...',
            status:   'closed'
          }
        }, @user_headers)
        expect_failed_field('project', "is closed")
      end


      it "returns errors if content is empty" do
        post( api_v1_project_tickets_path(@admin_project), {
          ticket: {
            subject:  'broken too much',
            status:   'closed'
          }
        }, @user_headers)
        expect_failed_field('content', "can't be blank")
      end

      it "returns errors if status is wrong" do
        post( api_v1_project_tickets_path(@admin_project), {
          ticket: {
            subject:  'broken too much',
            content:  'completely...',
            status:   'wrong'
          }
        }, @user_headers)
        expect_failed_field('status', "is not included in the list")
      end

    end

    context "for guest" do

      it "returns 401 error" do
        post( api_v1_project_tickets_path(@user_project), {
          ticket: {
            subject:  'broken too much',
            content:  'completely...',
            status:   'closed'
          }
        })
        expect( response ).to have_http_status(401)
      end

    end

  end

  describe "PUT /api/tickets" do

    def expect_successfull_update(project, owner)
      expect( response ).to                         have_http_status(200)
      expect( json['status']).to                      eq('success')
      expect( json['ticket'].keys.count ).to          eq(6)
      expect( json['ticket']['subject'] ).to          eq('broken too much')
      expect( json['ticket']['content'] ).to          eq('completely...')
      expect( json['ticket']['status'] ).to           eq('closed')
      expect( json['ticket']['owner'] ).to            eq(owner.username)  
      expect( json['ticket']['project']['id'] ).to    eq(project.id)
      expect( json['ticket']['project']['name'] ).to  eq(project.name)
    end

    context "for admin" do

      it "updates any existing ticket" do
        put( api_v1_project_ticket_path(@admin_project, @ticket2), {
          ticket: {
            subject:  'broken too much',
            content:  'completely...',
            status:   'closed'
          }
        }, @admin_headers)
        expect_successfull_update(@admin_project,@user)
      end

      it "returns errors if status is wrong" do
        put( api_v1_project_ticket_path(@admin_project, @ticket2), {
          ticket: {
            subject:  'broken too much',
            content:  'completely...',
            status:   'wrong'
          }
        }, @admin_headers)
        expect_failed_field('status', "is not included in the list")
      end

      it "returns 401 error if ticket doesn't exist" do
        put( api_v1_project_ticket_path(@admin_project, 9999), {
          ticket: {
            subject:  'broken too much',
            content:  'completely...',
            status:   'closed'
          }
        }, @admin_headers)
        expect( response ).to have_http_status(401)
      end

    end

    context "for user" do

      it "updates an owned ticket" do
        put( api_v1_project_ticket_path(@admin_project, @ticket2), {
          ticket: {
            subject:  'broken too much',
            content:  'completely...',
            status:   'closed'
          }
        }, @user_headers)
        expect_successfull_update(@admin_project,@user)
      end

      it "updates owned ticket if project is owned and closed" do
        put( api_v1_project_ticket_path(@user_project, @ticket3), {
          ticket: {
            subject:  'broken too much',
            content:  'completely...',
            status:   'closed'
          }
        }, @user_headers)
        expect_successfull_update(@user_project,@user)
      end

      it "returns errors if project isn't owned and closed" do
        @admin_project.update status: 'closed'
        put( api_v1_project_ticket_path(@admin_project, @ticket2), {
          ticket: {
            subject:  'broken too much',
            content:  'completely...',
            status:   'closed'
          }
        }, @user_headers)
        expect_failed_field('project', "is closed")
      end

      it "returns 401 error if ticket isn't owned" do
        @admin_project.update status: 'closed'
        put( api_v1_project_ticket_path(@admin_project, @ticket1), {
          ticket: {
            subject:  'broken too much',
            content:  'completely...',
            status:   'closed'
          }
        }, @user_headers)
        expect( response ).to have_http_status(401)
      end

      it "returns 401 error if ticket doesn't exist" do
        put( api_v1_project_ticket_path(@user_project, 9999), {
          ticket: {
            subject:  'broken too much',
            content:  'completely...',
            status:   'closed'
          }
        }, @user_headers)
        expect( response ).to have_http_status(401)
      end

    end

    context "for guest" do
      it "returns 401 error if ticket doesn't exist" do
        put( api_v1_project_ticket_path(@admin_project, @ticket2), {
          ticket: {
            subject:  'broken too much',
            content:  'completely...',
            status:   'closed'
          }
        })
        expect( response ).to have_http_status(401)
      end      
    end

  end

  describe "DELETE /api/project/:id" do

    context "for admin" do

      it "deletes any ticket" do
        delete api_v1_project_ticket_path(@admin_project, @ticket2), nil, @admin_headers     
        expect( response ).to have_http_status(200)
      end

      it "returns 401 error if user doesn't exist" do
        delete api_v1_project_ticket_path(@admin_project, 9999), nil, @admin_headers     
        expect( response ).to have_http_status(401)
      end

    end

    context "for user" do

      it "deletes an owned ticket" do
        delete api_v1_project_ticket_path(@admin_project, @ticket2), nil, @user_headers     
        expect( response ).to have_http_status(200)
      end

      it "returns 401 for not owned ticket" do
        delete api_v1_project_ticket_path(@admin_project, @ticket1), nil, @user_headers     
        expect( response ).to have_http_status(401)
      end

      it "returns 401 if user doesn't exist" do
        delete api_v1_project_ticket_path(@admin_project, 9999), nil, @user_headers     
        expect( response ).to have_http_status(401)
      end

    end

    context "for guest" do
      it "returns 401" do
        delete api_v1_project_ticket_path(@admin_project, @ticket1)
        expect( response ).to have_http_status(401)
      end
    end

  end

end

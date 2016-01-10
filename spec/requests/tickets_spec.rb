require 'rails_helper'

RSpec.describe "Tickets", type: :request do

  let(:admin_headers) {
    { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'test1234') }
  }

  let(:user_headers) {
    { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('john', 'test1234') }
  }

  let(:user)                  { create :user  }
  let(:admin)                 { create :admin }

  let(:user_project)          { create :project, name: "User Project 1", user: user }
  let(:admin_project)         { create :project, name: "Admin Project 1", user: admin }

  let(:user_ticket)           { create :ticket, project: user_project, user: user }
  let(:admin_ticket)          { create :ticket, project: admin_project, user: admin }

  let(:user_tickets_count)    { 2 }
  let(:user_tickets)          { user_tickets_count.times {|n| create :ticket, subject: "User Ticket #{n+1}", user: user, project: user_project } }

  let(:admin_tickets_count)    { 2 }
  let(:admin_tickets)          { admin_tickets_count.times {|n| create :ticket, subject: "Admin Ticket #{n+1}", user: admin, project: admin_project } }

  def expect_successfull_list_response(args={})
    args = {page: 1, total_pages: 1, count: 1}.merge args
    expect( response ).to               have_http_status(200)
    expect( json['status']).to          eq('success')
    expect( json['tickets'].size).to   eq( args[:count] )
    expect( json['page']).to            eq( args[:page] )
    expect( json['total_pages']).to     eq( args[:total_pages] )
  end

  describe "GET /api/project/:project_id/tickets" do

    RSpec.shared_context "a tickets list response" do |headers|
      context "when there are count of tickets less than per_page" do
        it "returns a list of tickets" do
          user_ticket
          get api_v1_project_tickets_path(user_project), nil, headers ? send(headers) : nil
          expect_successfull_list_response
        end
      end

      context "when there are 7 tikets and per_page = 5 and page = 2" do
        let(:user_tickets_count) { 7 }
        it "returns only 2 projects" do
          Kaminari.config.default_per_page = 5
          user_tickets
          get api_v1_project_tickets_path(user_project), {page: 2}, headers ? send(headers) : nil
          expect_successfull_list_response count: 2, page: 2, total_pages: 2
        end
      end

    end

    context "when user is admin" do
      it_behaves_like "a tickets list response", :admin_headers
    end

    context "when user is user" do
      it_behaves_like "a tickets list response", :user_headers
    end

    context "when user is guest" do
      it_behaves_like "a tickets list response"
    end

  end

  def expect_successfull_entry_response(ticket)
    expect( response ).to                           have_http_status(200)
    expect( json['status']).to                      eq('success')
    expect( json['ticket'].keys.count ).to          eq(6)
    expect( json['ticket']['subject'] ).to          eq(ticket.subject)
    expect( json['ticket']['content'] ).to          eq(ticket.content)
    expect( json['ticket']['status'] ).to           eq(ticket.status)
    expect( json['ticket']['owner'] ).to            eq(ticket.user.username)
    expect( json['ticket']['project']['id'] ).to    eq(ticket.project_id)
    expect( json['ticket']['project']['name'] ).to  eq(ticket.project.name)
  end

  RSpec.shared_context "an ticket entry response" do |headers|
    context "when ticket exists" do
      it "returns a specific ticket" do
        get api_v1_project_ticket_path( admin_project, admin_ticket ), nil, headers ? send(headers) : nil
        expect_successfull_entry_response( admin_ticket )
      end
    end
    context "when project doesn't exist" do
      it "returns 404 error" do
        get api_v1_project_ticket_path( admin_project, 9999 ), nil, headers ? send(headers) : nil
        expect( response ).to have_http_status(404)
      end
    end    
  end

  describe "GET /api/project/:project_id/tickets/:id" do
    context "when user is admin" do
      it_behaves_like "an ticket entry response", :admin_headers
    end

    context "when user is user" do
      it_behaves_like "an ticket entry response", :user_headers
    end

    context "when user is guest" do
      it_behaves_like "an ticket entry response"
    end
  end

  def expect_failed_field(field, error)
    expect( response ).to                           have_http_status(400)
    expect( json['status']).to                      eq('failed')
    expect( json['ticket']['errors'].keys.count ).to  eq(1)
    expect( json['ticket']['errors'][field] ).to match_array([error])
  end

  def build_params(args={})
    merged = { subject: 'Ticket 1', content: 'Ticket Content', status: "open" }.merge args
    {ticket: merged }
  end

  RSpec.shared_context "a create ticket response" do |headers, ns|
    before(:each) { admin_project; user }

    context "when arguments are correct" do
      it "creates a new ticket" do
        post( api_v1_project_tickets_path(admin_project), build_params,  (headers ? send(headers) : nil))
        expect_successfull_entry_response( send(ns).tickets.find_by(subject: 'Ticket 1') )
      end
    end

    context "when project is owned and closed" do
      it "creates a new ticket" do
        owned_project = send("#{ns}_project")
        owned_project.update(status: 'closed')
        post( api_v1_project_tickets_path( owned_project ), build_params,  (headers ? send(headers) : nil))
        expect_successfull_entry_response( send(ns).tickets.find_by(subject: 'Ticket 1') )
      end
    end

    context "when project is owned and closed" do
      it "creates a new ticket" do
        owned_project = send("#{ns}_project")
        owned_project.update(status: 'closed')
        post( api_v1_project_tickets_path( owned_project ), build_params,  (headers ? send(headers) : nil))
        expect_successfull_entry_response( send(ns).tickets.find_by(subject: 'Ticket 1') )
      end
    end

    context "when project isn't owned and closed" do
      it "returns an error" do
        notowned_project = ns == :admin ? user_project : admin_project
        notowned_project.update(status: 'closed')
        post( api_v1_project_tickets_path( notowned_project ), build_params,  (headers ? send(headers) : nil))
        expect_failed_field('project', "is closed")
      end
    end

    context "when content is empty" do
      it "returns an error" do
        post( api_v1_project_tickets_path(admin_project), build_params(content: nil), (headers ? send(headers) : nil))
        expect_failed_field('content', "can't be blank")
      end
    end

    context "when status isn't valid" do
      it "returns an error" do
        post( api_v1_project_tickets_path(admin_project), build_params(status: 'wrong'), (headers ? send(headers) : nil))
        expect_failed_field('status', "is not included in the list")
      end
    end
  end

  describe "POST /api/project/:project_id/tickets" do
    context "when user is admin" do
      it_behaves_like "a create ticket response", :admin_headers, :admin
    end

    context "when user is user" do
      it_behaves_like "a create ticket response", :user_headers, :user
    end

    context "when user is guest" do
      it "returns 401 error" do
        post( api_v1_project_tickets_path(admin_project), build_params)
        expect( response ).to  have_http_status(401)
      end
    end
  end

  RSpec.shared_context "an update ticket response" do |headers, ns, existing_project, existing_ticket|
    context "when ticket is owned" do
      it "updates a ticket" do
        put(
          api_v1_project_ticket_path(send(existing_project), send(existing_ticket)),
          build_params(subject: 'Ticket 1.1', content: 'Ticket Content 1.1', status: 'closed'),
          (headers ? send(headers) : nil)
        )
        expect_successfull_entry_response( send(ns).tickets.find_by(subject: 'Ticket 1.1') )
      end
    end

    context "when ticket doesn't exist" do
      it "returns 404 error" do
        put(
          api_v1_project_ticket_path(send(existing_project), 9999),
          build_params(subject: 'Ticket 1.1', content: 'Ticket Content 1.1', status: 'closed'),
          (headers ? send(headers) : nil)
        )
        expect( response ).to  have_http_status(404)
      end
    end

    context "when content is empty" do
      it "returns an error" do
        put(
          api_v1_project_ticket_path(send(existing_project), send(existing_ticket)),
          build_params(subject: 'Ticket 1.1', content: '', status: 'closed'),
          (headers ? send(headers) : nil)
        )
        expect_failed_field('content', "can't be blank")
      end
    end

    context "when status isn't valid" do
      it "returns an error" do
        put(
          api_v1_project_ticket_path(send(existing_project), send(existing_ticket)),
          build_params(subject: 'Ticket 1.1', content: 'Ticket Content 1.1', status: 'wrong'),
          (headers ? send(headers) : nil)
        )
        expect_failed_field('status', "is not included in the list")
      end
    end

  end

  describe "PUT /api/project/:project_id/tickets" do
    context "when user is admin" do
      it_behaves_like "an update ticket response", :admin_headers, :admin, :admin_project, :admin_ticket

      context "when ticket isn't owned" do
        it "updates a ticket" do
          admin
          put(
            api_v1_project_ticket_path(user_project, user_ticket),
            build_params(subject: 'Ticket 1.1', content: 'Ticket Content 1.1', status: 'closed'),
            admin_headers
          )
          expect_successfull_entry_response( user.tickets.find_by(subject: 'Ticket 1.1') )
        end
      end
    end

    context "when user is user" do
      it_behaves_like "an update ticket response", :user_headers, :user, :user_project, :user_ticket

      context "when ticket isn't owned" do
        it "returns 401 error" do
          user
          put(
            api_v1_project_ticket_path(admin_project, admin_ticket),
            build_params(subject: 'Ticket 1.1', content: 'Ticket Content 1.1', status: 'closed'),
            user_headers
          )
          expect( response ).to  have_http_status(401)
        end
      end
    end

    context "when user is guest" do
      it "returns 401 error" do
        put( api_v1_project_ticket_path( admin_project, admin_ticket ), build_params )
        expect( response ).to  have_http_status(401)
      end
    end
  end

  RSpec.shared_context "a delete ticket response" do |headers, ns, existing_project, existing_ticket|
    context "when project is owned" do
      it "destroys it" do
        delete api_v1_project_ticket_path(send(existing_project), send(existing_ticket)),nil, (headers ? send(headers) : nil)
        expect( response ).to                           have_http_status(200)
        expect( json['status']).to                      eq('success')
      end        
    end

    context "when project doesn't exist" do
      it "returns 404 error" do
        delete api_v1_project_ticket_path(send(existing_project), 9999),nil, (headers ? send(headers) : nil)
        expect( response ).to                           have_http_status(404)
      end
    end

  end


  fdescribe "DELETE /api/project/:project_id/tickets/:id" do
    context "when user is admin" do
      it_behaves_like "a delete ticket response", :admin_headers, :admin, :admin_project, :admin_ticket

      context "when ticket isn't owned" do
        it "updates a ticket" do
          admin
          delete(
            api_v1_project_ticket_path(user_project, user_ticket),
            build_params(subject: 'Ticket 1.1', content: 'Ticket Content 1.1', status: 'closed'),
            admin_headers
          )
          expect( response ).to                           have_http_status(200)
          expect( json['status']).to                      eq('success')
        end
      end
    end

    context "when user is user" do
      it_behaves_like "a delete ticket response", :user_headers, :user, :user_project, :user_ticket

      context "when ticket isn't owned" do
        it "returns 401 error" do
          user
          delete(
            api_v1_project_ticket_path(admin_project, admin_ticket),
            build_params(subject: 'Ticket 1.1', content: 'Ticket Content 1.1', status: 'closed'),
            user_headers
          )
          expect( response ).to   have_http_status(401)
        end
      end
    end

    context "when user is guest" do
      it "returns 401 error" do
        delete api_v1_project_ticket_path(admin_project, admin_ticket)
        expect( response ).to  have_http_status(401)
      end
    end
  end

end

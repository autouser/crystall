require 'rails_helper'

RSpec.describe Ticket, type: :model do

  before(:each) do
    @project_owner  = User.create! username: 'mannie', password: 'test1234'
    @ticket_owner   = User.create! username: 'john', password: 'test1234'
    @project        = @project_owner.projects.create! name: 'Core System 1.0', status: 'open'
  end

  context "is valid" do
    
    it "with correct arguments" do
      ticket = @ticket_owner.tickets.new project: @project, subject: 'Not working', content: 'something'
      expect( ticket ).to be_valid
    end

    it "assigns default status" do
      ticket = @ticket_owner.tickets.create! project: @project, subject: 'Not working', content: 'something'
      expect( ticket.status ).to eq('open')
    end

  end

  context "is invalid" do

    it "with empty content" do
      ticket = @ticket_owner.tickets.new project: @project, subject: 'Not working'
      expect( ticket ).to_not be_valid
      expect( ticket.errors.size ).to eq(1)
      expect( ticket.errors.get(:content) ).to match_array(["can't be blank"])
    end

    it "with empty project" do
      ticket = @ticket_owner.tickets.new subject: 'Not working', content: 'something'
      expect( ticket ).to_not be_valid
      expect( ticket.errors.size ).to eq(1)
      expect( ticket.errors.get(:project) ).to match_array(["can't be blank"])
    end

    it "with empty user" do
      ticket = @project.tickets.new subject: 'Not working', content: 'something'
      expect( ticket ).to_not be_valid
      expect( ticket.errors.size ).to eq(1)
      expect( ticket.errors.get(:user) ).to match_array(["can't be blank"])
    end

  end

end

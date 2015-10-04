require 'rails_helper'

RSpec.describe Project, type: :model do

  before(:each) do
    @user = User.create! username: 'john', password: 'test1234'
  end

  context "is valid" do
    it "with correct arguments" do
      project = Project.create!(user: @user, name: 'Core 1.0', description: 'Core System', status: 'open')
      expect( project ).to be_valid
      expect( project.status ).to eq('open')
    end
  end

  context "is invalid" do

    it "with empty name" do
      project = Project.new(user: @user, description: 'Core', status: 'open')
      expect( project ).to_not be_valid
      expect( project.errors.size ).to eq(1)
      expect( project.errors.get(:name) ).to match_array(["can't be blank"])
    end

    it "with non unique name" do
      project1 = Project.create!(user: @user, name: 'Core 1.0', description: 'Core System', status: 'open')
      project2 = Project.new(user: @user, name: 'Core 1.0', description: 'Core System', status: 'open')
      expect( project2 ).to_not be_valid
      expect( project2.errors.size ).to eq(1)
      expect( project2.errors.get(:name) ).to match_array(["has already been taken"])
    end

    it "with empty status" do
      project = Project.new(user: @user, name: 'Core 1.0', description: 'Core System')
      expect( project ).to_not be_valid
      expect( project.errors.size ).to eq(1)
      expect( project.errors.get(:status) ).to match_array(["is not included in the list"])
    end

    it "with empty user" do
      project = Project.new(name: 'Core 1.0', description: 'Core System', status: 'open')
      expect( project ).to_not be_valid
      expect( project.errors.size ).to eq(1)
      expect( project.errors.get(:user) ).to match_array(["can't be blank"])
    end

  end

end

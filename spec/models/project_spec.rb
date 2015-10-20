require 'rails_helper'

RSpec.describe Project, type: :model do

  # let(:user) { User.create! username: 'john', password: 'test1234' }
  let(:user) { create :user }

  describe "when instantiated", focus: true do
    
    context "with correct arguments" do

      let(:project) { Project.new(user: user, name: 'Core 1.0', description: 'Core System', status: 'open') }

      it { expect( project ).to be_valid }

    end

    context "with empty name" do
      let(:project) { Project.new(user: user, description: 'Core System', status: 'open') }
      it { expect( project ).to have_one_error(:name, "can't be blank") }
    end

    context "with non unique name" do
      before(:example) { Project.create!(user: user, name: 'Core 1.0', description: 'Core System', status: 'open') }
      let(:project) { Project.new(user: user, name: 'Core 1.0', description: 'Core System', status: 'open') }
      it { expect( project ).to have_one_error(:name, "has already been taken") }
    end

    context "with empty status" do
      let(:project) { Project.new(user: user, name: 'Core 1.0', description: 'Core System', status: nil) }
      it { expect( project ).to have_one_error(:status, "is not included in the list") }
    end

    context "with wrong status" do
      let(:project) { Project.new(user: user, name: 'Core 1.0', description: 'Core System', status: "wrong") }
      it { expect( project ).to have_one_error(:status, "is not included in the list") }
    end


    context "with empty user" do
      let(:project) { Project.new(user: nil, name: 'Core 1.0', description: 'Core System', status: "open") }
      it { expect( project ).to have_one_error(:user, "can't be blank") }
    end

  end

end

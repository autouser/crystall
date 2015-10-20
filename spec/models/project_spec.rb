require 'rails_helper'

RSpec.describe Project, type: :model do

  let(:user) { create :user }

  describe "when instantiated" do
    
    context "with correct arguments" do

      let(:project) { build :project, user: user }

      it { expect( project ).to be_valid }

    end

    context "with empty name" do
      let(:project) { build :project, user: user, name: nil }

      it { expect( project ).to have_one_error(:name, "can't be blank") }
    end

    context "with non unique name" do
      before(:example) { create :project, user: user }
      let(:project) { build :project, user: user }

      it { expect( project ).to have_one_error(:name, "has already been taken") }
    end

    context "with empty status" do
      let(:project) { build :project, user: user, status: nil }

      it { expect( project ).to have_one_error(:status, "is not included in the list") }
    end

    context "with wrong status" do
      let(:project) { build :project, user: user, status: 'wrong' }

      it { expect( project ).to have_one_error(:status, "is not included in the list") }
    end


    context "with empty user" do
      let(:project) { build :project, user: nil }
      
      it { expect( project ).to have_one_error(:user, "can't be blank") }
    end

  end

end

require 'rails_helper'

RSpec.describe User, type: :model do

  describe "when instantiated" do
    
    context "with correct arguments" do
      let(:user) { build :user }

      it { expect( user ).to be_valid }
    end

    context "with empty username" do
      let(:user) { build :user, username: nil }

      it { expect( user ).to have_one_error(:username, "can't be blank") }
    end

    context "with non unique username" do
      before(:example) { create :user }
      let(:user) { build :user }

      it { expect( user ).to have_one_error(:username, "has already been taken") }
    end

    context "with empty password" do
      let(:user) { build :user, password: nil }

      it { expect( user ).to have_one_error(:password, "can't be blank") }
    end
  end

end

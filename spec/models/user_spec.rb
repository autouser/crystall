require 'rails_helper'

RSpec.describe User, type: :model do

  context "is valid" do
    it "with correct arguments" do
      user = User.create username: 'john', password: 'test1234'
      expect( user ).to be_valid
      expect( user.username ).to eq('john')
    end
  end

  context "is invalid" do
    
    it "with empty username" do
      user = User.new password: 'test1234'
      expect( user ).to_not be_valid
      expect( user.errors.size ).to eq(1)
      expect( user.errors.get(:username) ).to match_array(["can't be blank"])
    end

    it "with non unique username" do
      user1 = User.create! username: 'john', password: 'test1234'
      user2 = User.new username: 'john', password: 'test1234'
      expect( user2 ).to_not be_valid
      expect( user2.errors.size ).to eq(1)
      expect( user2.errors.get(:username) ).to match_array("has already been taken")
    end

    it "with empty password" do
      user = User.new username: 'john'
      expect( user ).to_not be_valid
      expect( user.errors.size ).to eq(1)
      expect( user.errors.get(:password) ).to match_array(["can't be blank"])
    end

  end

end

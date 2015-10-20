require 'rails_helper'

RSpec.describe Ticket, type: :model do

  let(:project_owner) { build :user }
  let(:ticket_owner)  { project_owner }
  let(:project)       { build :project, user: project_owner }

    context "with correct arguments" do
      let(:ticket) { build :ticket, user: ticket_owner, status: nil }

      it { expect( ticket ).to be_valid }
      it { ticket.valid? ; expect( ticket ).to have_field_with_value(:status, "open") }
    end

    context "with empty content" do
      let(:ticket) { build :ticket, user: ticket_owner, content: nil }

      it { expect( ticket ).to have_one_error(:content, "can't be blank") }
    end

    context "with empty project" do
      let(:ticket) { build :ticket, user: ticket_owner, project: nil }

      it { expect( ticket ).to have_one_error(:project, "can't be blank") }
    end

    context "with empty user" do
      let(:ticket) { build :ticket, user: nil }

      it { expect( ticket ).to have_one_error(:user, "can't be blank") }
    end

end

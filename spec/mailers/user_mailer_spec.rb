require "rails_helper"

RSpec.describe UserMailer do

  let_there_be_lane
  let_there_be_j
  fake_login_for_each_test

  let(:identity)              { create(:identity) }
  let(:protocol)              { create(:study_without_validations,
                                primary_pi: identity,
                                selected_for_epic: true) }
  let(:project_role)          { create(:project_role, 
                                protocol: protocol, 
                                identity: identity) }
  let(:added_identity)        { create(:identity) }
  let(:added_project_role)    { create(:project_role, 
                                        protocol: protocol, 
                                        identity: added_identity) }

  context "added a authorized user" do
    before do
      @send_to = identity
    end
  
    it '' do
      UserMailer.authorized_user_changed(identity, protocol, added_identity, 'added').deliver
    end
  end
end
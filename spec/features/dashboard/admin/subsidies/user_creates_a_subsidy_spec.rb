require 'rails_helper'

RSpec.describe "admin subsidy", js: true do
  let_there_be_lane
  fake_login_for_each_test

  describe 'user clicks request a subsidy' do

    let!(:protocol)            { create(:protocol_without_validations, type: 'Study') }
    let!(:service_request)     { create(:service_request_without_validations, protocol: protocol) }
    let!(:institution)         { create(:institution) }
    let!(:subsidy_map)         { create(:subsidy_map, organization: institution, max_dollar_cap: 30, max_percentage: 50.00) }
    let!(:sub_service_request) { create(:sub_service_request_without_validations, service_request: service_request,
                                 organization: institution, status: 'submitted') }
    let!(:arm)                 { create(:arm, name: "Arm", protocol: protocol, visit_count: 1, subject_count: 1) }
    let!(:visit_group)         { create(:visit_group, arm: arm, position: 1, day: 1) }
    let!(:project_role)        { create(:project_role, protocol: protocol, identity: Identity.find_by_ldap_uid('jug2'),
                                 project_rights: 'approve', role: 'primary-pi') }
    let!(:admin)               { create(:super_user, organization: institution, identity: Identity.find_by_ldap_uid('jug2')) }

    it 'should bring up the subsidy modal' do
      visit dashboard_sub_service_request_path(sub_service_request.id)
      click_button 'Request a Subsidy'
      wait_for_javascript_to_finish
      expect(page).to have_content('New Subsidy Pending Approval')
    end
  end
end
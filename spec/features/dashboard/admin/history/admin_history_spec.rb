require 'rails_helper'

RSpec.describe 'admin history', js: true do
  let_there_be_lane
  fake_login_for_each_test

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
  let!(:pricing_setup)       { create(:pricing_setup, organization: institution) }
  let!(:service)             { create(:service, organization: institution, name: 'Stay out of dat personal space') }
  let!(:line_item)           { create(:line_item, service_request: service_request, service: service,
                               sub_service_request: sub_service_request, quantity: 1) }
  let!(:line_items_visit)    { create(:line_items_visit, line_item: line_item, arm: arm, subject_count: 1) }
  let!(:visit1)              { create(:visit, visit_group: visit_group, line_items_visit: line_items_visit,
                               research_billing_qty: 1) }
  let!(:pricing_map)         { create(:pricing_map, unit_minimum: 1, unit_factor: 1, service_id: service.id,
                               display_date: Time.now - 1.day, full_rate: 1000, federal_rate: 1000, units_per_qty_max: 20) }

  describe 'admin changes status' do

    it 'should change the status' do
      visit_admin_history_tab
      bootstrap_select "#sub_service_request_status", 'Draft'
      expect(sub_service_request.reload.status).to eq('draft')
    end
  end

    # it 'should be added to the history log' do



  def visit_admin_history_tab
    visit dashboard_sub_service_request_path(sub_service_request.id)
    click_link('History')
    wait_for_javascript_to_finish
  end
end
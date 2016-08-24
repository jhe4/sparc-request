require 'rails_helper'

RSpec.describe 'user manages services', js: true do

  let_there_be_lane
  fake_login_for_each_test

  let!(:protocol)            { create(:protocol_without_validations, type: 'Study') }
  let!(:service_request)     { create(:service_request_without_validations, protocol: protocol) }
  let!(:institution)         { create(:institution) }
  let!(:sub_service_request) { create(:sub_service_request_without_validations, service_request: service_request,
                               organization: institution, status: 'submitted') }
  let!(:arm)                 { create(:arm, name: 'Two Brothers', protocol: protocol, visit_count: 1, subject_count: 1) }
  let!(:visit_group)         { create(:visit_group, arm: arm, position: 1, day: 1) }
  let!(:project_role)        { create(:project_role, protocol: protocol, identity: Identity.find_by_ldap_uid('jug2'),
                               project_rights: 'approve', role: 'primary-pi') }
  let!(:admin)               { create(:super_user, organization: institution, identity: Identity.find_by_ldap_uid('jug2')) }
  let!(:pricing_setup)       { create(:pricing_setup, organization: institution) }
  let!(:service)             { create(:service, organization: institution, name: 'Little Bits') }
  let!(:service2)            { create(:service, organization: institution, name: 'Tiny Lasagna') }
  let!(:line_item)           { create(:line_item, service_request: service_request, service: service,
                               sub_service_request: sub_service_request, quantity: 1) }
  let!(:line_items_visit)    { create(:line_items_visit, line_item: line_item, arm: arm, subject_count: 1) }
  let!(:visit1)              { create(:visit, visit_group: visit_group, line_items_visit: line_items_visit,
                               research_billing_qty: 1) }
  let!(:pricing_map)         { create(:pricing_map, unit_minimum: 1, unit_factor: 1, service_id: service.id,
                               display_date: Time.now - 1.day, full_rate: 1000, federal_rate: 1000, units_per_qty_max: 20) }

  describe 'clicking the add service button' do

    it 'should bring up the add services modal' do
      visit_admin_section_and_go_to_study_schedule('#add_service_button')
      expect(page).to have_content('Add Service')
    end

    it 'should create a line item' do
      visit_admin_section_and_go_to_study_schedule('#add_service_button')
      bootstrap_select "#add_service_id", 'Tiny Lasagna'
      click_button 'Add'
      expect(page).to have_content('Tiny Lasagna')
    end
  end


  def visit_admin_section_and_go_to_study_schedule(id)
    visit dashboard_sub_service_request_path(sub_service_request.id)
    click_link 'Study Schedule'
    wait_for_javascript_to_finish
    find(id).click
    wait_for_javascript_to_finish
  end
end
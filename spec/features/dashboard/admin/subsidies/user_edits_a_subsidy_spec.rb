require 'rails_helper'

RSpec.describe 'user edits a subsidy', js: true do
  let_there_be_lane
  fake_login_for_each_test

  before :each do
    protocol             = create(:protocol_without_validations, type: 'Study')
    service_request      = create(:service_request_without_validations, protocol: protocol)
    institution          = create(:institution)
    @sub_service_request = create(:sub_service_request_without_validations, service_request: service_request,
                                   organization: institution, status: 'submitted')
    arm                  = create(:arm, name: 'In a Van', protocol: protocol, visit_count: 1, subject_count: 1)
    visit_group          = create(:visit_group, arm: arm, position: 1, day: 1)
    service              = create(:service, organization: institution, name: 'Little Bits')
    line_item            = create(:line_item, service_request: service_request, service: service,
                                   sub_service_request: @sub_service_request, quantity: 1)
    line_items_visit     = create(:line_items_visit, line_item: line_item, arm: arm, subject_count: 1)
    create(:subsidy_map, organization: institution, max_dollar_cap: 30, max_percentage: 50.00)
    create(:visit, visit_group: visit_group, line_items_visit: line_items_visit, research_billing_qty: 1)
    create(:project_role, protocol: protocol, identity: Identity.find_by_ldap_uid('jug2'),
            project_rights: 'approve', role: 'primary-pi')
    create(:super_user, organization: institution, identity: Identity.find_by_ldap_uid('jug2'))
    create(:pricing_setup, organization: institution)
    create(:pricing_map, unit_minimum: 1, unit_factor: 1, service_id: service.id,
            display_date: Time.now - 1.day, full_rate: 1000, federal_rate: 1000, units_per_qty_max: 20)
  end

  describe 'user edits a subsidy' do

    it 'should save the new values' do
      visit_admin_section_and_request_subsidy
      create_a_new_subsidy
      find('#edit_subsidy_button').click
      find('#pending_subsidy_percent_subsidy').set("20\n")
      click_button 'Save'
      wait_for_javascript_to_finish
      expect(find('.subsidy_percent').text).to eq('20.0')
    end
  end

  def visit_admin_section_and_request_subsidy
    visit dashboard_sub_service_request_path(@sub_service_request.id)
    click_button 'Request a Subsidy'
    wait_for_javascript_to_finish
  end

  def create_a_new_subsidy
    find('#pending_subsidy_percent_subsidy').set("20\n")
    click_button 'Save'
    wait_for_javascript_to_finish
  end
end
require 'rails_helper'

RSpec.describe 'user creates a subsidy', js: true do
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
    @subsidy_map          = create(:subsidy_map, organization: institution, max_dollar_cap: 30, max_percentage: 50.00)
    create(:visit, visit_group: visit_group, line_items_visit: line_items_visit, research_billing_qty: 1)
    create(:project_role, protocol: protocol, identity: Identity.find_by_ldap_uid('jug2'),
            project_rights: 'approve', role: 'primary-pi')
    create(:super_user, organization: institution, identity: Identity.find_by_ldap_uid('jug2'))
    create(:pricing_setup, organization: institution)
    create(:pricing_map, unit_minimum: 1, unit_factor: 1, service_id: service.id,
            display_date: Time.now - 1.day, full_rate: 1000, federal_rate: 1000, units_per_qty_max: 20)
  end

  describe 'user clicks request a subsidy' do

    it 'should bring up the subsidy modal' do
      visit_admin_section_and_request_subsidy
      expect(page).to have_content('New Subsidy Pending Approval')
    end
  end

  describe 'user creates a subsidy' do

    it 'should create a pending subsidy' do
      visit_admin_section_and_request_subsidy
      find('#pending_subsidy_percent_subsidy').set("20\n")
      expect(page).to have_content('Subsidy Pending Approval')
    end

    context 'validations and calculations' do

      it 'should not allow the admin to set the percent subsidy to zero' do
        visit_admin_section_and_request_subsidy
        click_button 'Save'
        expect(page).to have_content('Percent subsidy can not be 0')
      end

      it 'should calculate the pi contribution if the percent subsidy is set' do
        visit_admin_section_and_request_subsidy
        find('#pending_subsidy_percent_subsidy').set("20\n")
        pi_contribution = find('#pending_subsidy_pi_contribution').value
        expect(pi_contribution).to eq('8.00')
      end

      it 'should calculate the percent subsidy if the pi contribution is set' do
        visit_admin_section_and_request_subsidy
        find('#pending_subsidy_pi_contribution').set("8\n")
        percent = find('#pending_subsidy_percent_subsidy').value
        expect(percent).to eq('20.00')
      end 
    end

    context 'default percentage' do

      it 'should populate the percent subsidy with the default percentage if it is set' do
        @subsidy_map.update_attributes(default_percentage: 5)
        visit_admin_section_and_request_subsidy
        percent = find('#pending_subsidy_percent_subsidy').value
        expect(percent).to eq('5.0')
      end
    end
  end

  def visit_admin_section_and_request_subsidy
    visit dashboard_sub_service_request_path(@sub_service_request.id)
    click_button 'Request a Subsidy'
    wait_for_javascript_to_finish
  end
end
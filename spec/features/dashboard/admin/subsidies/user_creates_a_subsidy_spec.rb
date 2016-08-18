require 'rails_helper'

RSpec.describe "admin subsidy", js: true do
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

  describe 'user clicks request a subsidy' do

    it 'should bring up the subsidy modal' do
      visit dashboard_sub_service_request_path(sub_service_request.id)
      click_button 'Request a Subsidy'
      expect(page).to have_content('New Subsidy Pending Approval')
    end
  end

  describe 'user creates a subsidy' do

    let!(:pricing_setup)    { create(:pricing_setup, organization: institution) }
    let!(:service)          { create(:service, organization: institution, name: 'Personal Space') }
    let!(:line_item)        { create(:line_item, service_request: service_request, service: service,
                              sub_service_request: sub_service_request, quantity: 1) }
    let!(:line_items_visit) { create(:line_items_visit, line_item: line_item, arm: arm, subject_count: 1) }
    let!(:visit1)            { create(:visit, visit_group: visit_group, line_items_visit: line_items_visit,
                              research_billing_qty: 1) }
    let!(:pricing_map)      { create(:pricing_map, unit_minimum: 1, unit_factor: 1, service_id: service.id,
                              display_date: Time.now - 1.day, full_rate: 1000, federal_rate: 1000, units_per_qty_max: 20) }


    it 'should create a pending subsidy' do
      visit dashboard_sub_service_request_path(sub_service_request.id)
      click_button 'Request a Subsidy'
      wait_for_javascript_to_finish
      find('#pending_subsidy_percent_subsidy').set("20\n")
      expect(page).to have_content('Subsidy Pending Approval')
    end

    context 'validations and calculations' do

      it 'should not allow the admin to set the percent subsidy to zero' do
        visit dashboard_sub_service_request_path(sub_service_request.id)
        click_button 'Request a Subsidy'
        wait_for_javascript_to_finish
        click_button 'Save'
        expect(page).to have_content('Percent subsidy can not be 0')
      end

      it 'should calculate the pi contribution if the percent subsidy is set' do
        visit dashboard_sub_service_request_path(sub_service_request.id)
        click_button 'Request a Subsidy'
        wait_for_javascript_to_finish
        find('#pending_subsidy_percent_subsidy').set("20\n")
        pi_contribution = find('#pending_subsidy_pi_contribution').value
        expect(pi_contribution).to eq('8.00')
      end

      it 'should calculate the percent subsidy if the pi contribution is set' do
        visit dashboard_sub_service_request_path(sub_service_request.id)
        click_button 'Request a Subsidy'
        wait_for_javascript_to_finish
        find('#pending_subsidy_pi_contribution').set("8\n")
        percent = find('#pending_subsidy_percent_subsidy').value
        expect(percent).to eq('20.00')
      end 
    end

    context 'default percentage' do

      it 'should populate the percent subsidy with the default percentage if it is set' do
        subsidy_map.update_attributes(default_percentage: 5)
        visit dashboard_sub_service_request_path(sub_service_request.id)
        click_button 'Request a Subsidy'
        wait_for_javascript_to_finish
        percent = find('#pending_subsidy_percent_subsidy').value
        expect(percent).to eq('5.0')
      end
    end
  end
end
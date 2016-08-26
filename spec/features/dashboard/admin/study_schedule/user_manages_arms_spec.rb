require 'rails_helper'

RSpec.describe 'user manages arms', js: true do

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
    create(:visit, visit_group: visit_group, line_items_visit: line_items_visit, research_billing_qty: 1)
    create(:project_role, protocol: protocol, identity: Identity.find_by_ldap_uid('jug2'),
            project_rights: 'approve', role: 'primary-pi')
    create(:super_user, organization: institution, identity: Identity.find_by_ldap_uid('jug2'))
    create(:pricing_setup, organization: institution)
    create(:pricing_map, unit_minimum: 1, unit_factor: 1, service_id: service.id,
            display_date: Time.now - 1.day, full_rate: 1000, federal_rate: 1000, units_per_qty_max: 20)
  end

  describe 'clicking the add arm button' do

    it 'should bring up the modal' do
      visit_admin_section_and_go_to_study_schedule('#add_arm_button')
      expect(page).to have_content('Add Arm')
    end

    it 'should validate for the name' do
      visit_admin_section_and_go_to_study_schedule('#add_arm_button')
      click_button 'Add'
      expect(page).to have_content("Name can't be blank")
    end

    it 'should add the arm' do
      visit_admin_section_and_go_to_study_schedule('#add_arm_button')
      find('#arm_name').set('Real Fake Doors')
      click_button 'Add'
      expect(page).to have_content('Per Patient/Visit Services -- Real Fake Doors')
    end
  end

  describe 'clicking the edit arm button' do

    it 'should change the arm name' do
      visit_admin_section_and_go_to_study_schedule('#edit_arm_button')
      find('#arm_name').set('Jan Michael Vincent')
      click_button 'Save'
      expect(page).to have_content('Per Patient/Visit Services -- Jan Michael Vincent')
    end
  end

  def visit_admin_section_and_go_to_study_schedule(id)
    visit dashboard_sub_service_request_path(@sub_service_request.id)
    click_link 'Study Schedule'
    wait_for_javascript_to_finish
    find(id).click
    wait_for_javascript_to_finish
  end
end
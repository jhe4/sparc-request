require "rails_helper"

RSpec.describe UserMailer do

  let_there_be_lane
  let_there_be_j
  fake_login_for_each_test


  context "added a authorized user" do
    before :each do
      @modified_identity        = create(:identity)
      @protocol                 = create(:study_without_validations, selected_for_epic: false, funding_status: 'funded', funding_source: 'federal')
                                  create(:project_role, protocol: @protocol, identity: @modified_identity, project_rights: 'approve', role: 'consultant')
      @identity                 = create(:identity)
      @protocol_role            = create(:project_role, protocol: @protocol, identity: @identity, project_rights: 'approve', role: 'consultant')
      @mail = UserMailer.authorized_user_changed(@identity, @protocol, @modified_identity, 'add')
    end
  
    it "should display the 'added' message" do
      # An Authorized User has been added in SparcDashboard ***(link to protocol)***
      expect(@mail).to have_xpath("//p[normalize-space(text()) = 'An Authorized User has been added in']")
      expect(@mail).to have_xpath "//p//a[@href='/dashboard/protocols/#{@protocol.id}'][text()= 'SPARCDashboard.']/@href"
    end

    it "should display the Protocol information table" do
      expect(@mail).to have_xpath "//table//strong[text()='Study Information']"
      expect(@mail).to have_xpath "//th[text()='Study ID']/following-sibling::td[text()='#{@protocol.id}']"
      expect(@mail).to have_xpath "//th[text()='Short Title']/following-sibling::td[text()='#{@protocol.short_title}']"
      expect(@mail).to have_xpath "//th[text()='Study Title']/following-sibling::td[text()='#{@protocol.title}']"
      expect(@mail).to have_xpath "//th[text()='Sponsor Name']/following-sibling::td[text()='#{@protocol.sponsor_name}']"
      expect(@mail).to have_xpath "//th[text()='Funding Source']/following-sibling::td[text()='#{@protocol.funding_source.capitalize}']"
    end

    it "should display the User Information table" do
      expect(@mail).to have_xpath "//table//strong[text()='User Information']"
      expect(@mail).to have_xpath "//th[text()='User Name']/following-sibling::th[text()='Contact Information']/following-sibling::th[text()='Role']"
      @protocol.project_roles.each do |role|
        if @identity.id == role.identity.id
          requester_flag = " (Requester)"
        else
          requester_flag = ""
        end
        expect(@mail).to have_xpath "//td[text()='#{role.identity.full_name}']/following-sibling::td[text()='#{role.identity.email}']/following-sibling::td[text()='#{role.role.upcase}#{requester_flag}']"
    end
  end
end
require "rails_helper"

RSpec.describe UserMailer do

  let_there_be_lane
  let_there_be_j
  fake_login_for_each_test
  build_service_request_with_study

  context "added a authorized user" do
    before :each do
      @modified_identity        = create(:identity)
      @identity                 = create(:identity)
      @protocol_role            = create(:project_role, protocol: study, identity: @modified_identity, project_rights: 'approve', role: 'consultant')
      @mail = UserMailer.authorized_user_changed(@identity, study, @modified_identity, 'add')
    end
  
    it "should display the 'added' message" do
      # An Authorized User has been added in SparcDashboard ***(link to protocol)***
      expect(@mail).to have_xpath("//p[normalize-space(text()) = 'An Authorized User has been added in']")
      expect(@mail).to have_xpath "//p//a[@href='/dashboard/protocols/#{study.id}'][text()= 'SPARCDashboard.']/@href"
    end

    it "should display the Protocol information table" do
      expect(@mail).to have_xpath "//table//strong[text()='Study Information']"
      expect(@mail).to have_xpath "//th[text()='Study ID']/following-sibling::td[text()='#{study.id}']"
      expect(@mail).to have_xpath "//th[text()='Short Title']/following-sibling::td[text()='#{study.short_title}']"
      expect(@mail).to have_xpath "//th[text()='Study Title']/following-sibling::td[text()='#{study.title}']"
      expect(@mail).to have_xpath "//th[text()='Sponsor Name']/following-sibling::td[text()='#{study.sponsor_name}']"
      expect(@mail).to have_xpath "//th[text()='Funding Source']/following-sibling::td[text()='#{study.funding_source.capitalize}']"
    end

    it "should display the User Information table" do
      expect(@mail).to have_xpath "//table//strong[text()='User Information']"
      expect(@mail).to have_xpath "//th[text()='User Modification']/following-sibling::th[text()='Contact Information']/following-sibling::th[text()='Role']/following-sibling::th[text()='SPARC Proxy Rights']/following-sibling::th[text()='Epic Access']"
      expect(@mail).to have_xpath "//td[text()='#{@modified_identity.full_name}']/following-sibling::td[text()='#{@modified_identity.email}']/following-sibling::td[text()='#{@modified_identity.project_roles.first.role.upcase}']/following-sibling::td[text()='#{@modified_identity.project_roles.first.display_rights}']"
      if @modified_identity.project_roles.first.epic_access == false
        expect(@mail).to have_xpath "//td[text()='No']"
      else
        expect(@mail).to have_xpath "//td[text()='Yes']"
      end
    end

    it "should display ack" do
      binding.pry
    end
  end
end
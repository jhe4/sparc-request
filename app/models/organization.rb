# Copyright © 2011-2016 MUSC Foundation for Research Development
# All rights reserved.

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
# disclaimer in the documentation and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

class Organization < ActiveRecord::Base

  include RemotelyNotifiable

  audited
  acts_as_taggable

  before_save :compute_lft_and_rgt

  belongs_to :parent, :class_name => 'Organization'
  has_many :submission_emails, :dependent => :destroy
  has_many :associated_surveys, as: :surveyable
  has_many :pricing_setups, :dependent => :destroy
  has_one :subsidy_map, :dependent => :destroy

  has_many :super_users, :dependent => :destroy
  has_many :identities, :through => :super_users

  has_many :service_providers, :dependent => :destroy
  has_many :identities, :through => :service_providers

  has_many :catalog_managers, :dependent => :destroy
  has_many :clinical_providers, :dependent => :destroy
  has_many :identities, :through => :catalog_managers
  has_many :services, :dependent => :destroy
  has_many :sub_service_requests, :dependent => :destroy
  has_many :protocols, through: :sub_service_requests
  has_many :available_statuses, :dependent => :destroy
  has_many :org_children, class_name: "Organization", foreign_key: :parent_id


  attr_accessible :abbreviation
  attr_accessible :ack_language
  attr_accessible :available_statuses_attributes
  attr_accessible :css_class
  attr_accessible :description
  attr_accessible :is_available
  attr_accessible :lft
  attr_accessible :name
  attr_accessible :order
  attr_accessible :parent_id
  attr_accessible :pricing_setups_attributes
  attr_accessible :process_ssrs
  attr_accessible :rgt
  attr_accessible :submission_emails_attributes
  attr_accessible :subsidy_map_attributes
  attr_accessible :tag_list

  accepts_nested_attributes_for :subsidy_map
  accepts_nested_attributes_for :pricing_setups
  accepts_nested_attributes_for :submission_emails
  accepts_nested_attributes_for :available_statuses, :allow_destroy => true

  # TODO: In rails 5, the .or operator will be added for ActiveRecord queries. We should try to
  #       condense this to a single query at that point
  scope :authorized_for_identity, -> (identity_id) {
    orgs = includes(:super_users, :service_providers).where("super_users.identity_id = ? or service_providers.identity_id = ?", identity_id, identity_id).references(:super_users, :service_providers).uniq(:organizations)
    where(id: orgs + Organization.authorized_child_organizations(orgs.map(&:id))).distinct
  }

  scope :in_cwf, -> { joins(:tags).where(tags: { name: 'clinical work fulfillment' }) }

  scope :available_institutions, -> {
    Organization.where(type: 'Institution', is_available: true)
  }

  scope :available_providers, -> {
    Organization.where(type: 'Provider', is_available: true, parent: available_institutions)
  }

  scope :available_programs, -> {
    Organization.where(type: 'Program', is_available: true, parent: available_providers)
  }

  scope :available_cores, -> {
    Organization.where(type: 'Core', is_available: true, parent: available_programs)
  }

  def label
    abbreviation || name
  end

  ###############################################################################
  ############################# HIERARCHY METHODS ###############################
  ###############################################################################

  # Returns an array of organizations, the current organization's parents, in order of climbing
  # the tree backwards (thus if called on a core it will return => [program, provider, institution]).
  def parents(id_only=false)
    orgs = Organization.where("lft < ? AND rgt > ?", lft, rgt).
      order(lft: :desc)
    id_only ? orgs.pluck(:id) : orgs
  end

  def parents_and_self
    Organization.where("lft <= ? AND rgt >= ?", lft, rgt).
      order(lft: :desc)
  end

  # Returns the first organization amongst the current organization's parents where the process_ssrs
  # flag is set to true.  Will return self if self has the flag set true.  Will return nil if no
  # organization in the hierarchy is found that has the flag set to true.
  def process_ssrs_parent
    process_ssrs? ? self : parents.find_by(process_ssrs: true)
  end

  def service_providers_lookup
    org_with_providers = parents_and_self.
      joins(:service_providers).
      first
    org_with_providers ? org_with_providers.service_providers : Organization.none
  end

  def submission_emails_lookup
    org_with_emails = parents_and_self.
      joins(:submission_emails).
      first
    org_with_emails ? org_with_emails.submission_emails : Organization.none
  end

  # If an organization or one of it's parents is defined as lockable in the application.yml, return true
  def has_editable_statuses?
    parents_and_self.where(id: EDITABLE_STATUSES.keys).any?
  end

  def all_child_organizations
    Organization.where("lft > ? AND rgt < ?", lft, rgt).
      order(lft: :asc)
  end

  def child_orgs_with_protocols
    all_child_organizations.joins(:protocols).distinct
  end

  # Returns an array of all children (and children of children) of this organization (deep search).
  # Optionally includes self
  # TODO: doesn't actually include self, look into this
  # Only usage is passing Organization.all as orgs.
  def all_children
    Organization.where("lft >= ? AND rgt <= ?", lft, rgt).
      order(lft: :asc)
  end

  def update_descendants_availability(is_available)
    if is_available == "false"
      all_children.update_all(is_available: false)
      all_child_services.update_all(is_available: false)
    end
  end

  # Returns an array of all services that are offered by this organization as well of all of its
  # deep children.
  def all_child_services(include_self=true)
    if include_self
      Service.joins(:organization).
        where("organizations.lft >= ? AND organizations.rgt <= ?", lft, rgt)
    else
      Service.joins(:organization).
        where("organizations.lft > ? AND organizations.rgt < ?", lft, rgt)
    end.order(:name)
  end

  ###############################################################################
  ############################## PRICING METHODS ################################
  ###############################################################################

  # Returns this organization's pricing setup that is displayed on todays date.
  def current_pricing_setup
    return pricing_setup_for_date(Date.today)
  end

  # Returns this organization's pricing setup that is displayed on a given date.
  def pricing_setup_for_date(date)
    if self.pricing_setups.blank?
      raise ArgumentError, "Organization has no pricing setups" if self.parent.nil?
      return self.parent.pricing_setup_for_date(date)
    end

    current_setups = self.pricing_setups.select { |x| x.display_date.to_date <= date.to_date }

    raise ArgumentError, "Organization has no current pricing setups" if current_setups.empty?
    sorted_setups = current_setups.sort { |lhs, rhs| lhs.display_date <=> rhs.display_date }
    pricing_setup = sorted_setups.last

    return pricing_setup
  end

  # Returns this organization's pricing setup that is effective on a given date.
  def effective_pricing_setup_for_date(date=Date.today)
    if self.pricing_setups.blank?
      raise ArgumentError, "Organization has no pricing setups" if self.parent.nil?
      return self.parent.effective_pricing_setup_for_date(date)
    end

    current_setups = self.pricing_setups.select { |x| x.effective_date.to_date <= date.to_date }

    raise ArgumentError, "Organization has no current effective pricing setups" if current_setups.empty?
    sorted_setups = current_setups.sort { |lhs, rhs| lhs.effective_date <=> rhs.effective_date }
    pricing_setup = sorted_setups.last

    return pricing_setup
  end

  ###############################################################################
  ############################## SUBSIDY METHODS ################################
  ###############################################################################

  # Returns true if the funding source specified is an excluded funding source of this organization.
  # Otherwise, returns false.
  def funding_source_excluded_from_subsidy?(funding_source)
    excluded = false
    excluded_funding_sources = self.try(:subsidy_map).try(:excluded_funding_sources)
    if excluded_funding_sources
      funding_source_names = excluded_funding_sources.map {|x| x.funding_source}
      excluded = true if funding_source_names.include?(funding_source)
    end

    excluded
  end

  # Returns true if this organization has any information (greater than 0) in its subsidy map.
  # It is assumed that if any information has been entered that the organization offers subsidies.
  def eligible_for_subsidy?
    eligible = false

    if subsidy_map then
      eligible = true if subsidy_map.max_dollar_cap and subsidy_map.max_dollar_cap > 0
      eligible = true if subsidy_map.max_percentage and subsidy_map.max_percentage > 0
    end

    return eligible
  end

  ###############################################################################
  ############################ RELATIONSHIP METHODS #############################
  ###############################################################################

  # Looks down through all child services. It looks back up through each service's parent organizations
  # and returns false if any of them do not have a service provider. Self is excluded.
  def service_providers_for_child_services?
    has_provider = true
    if !self.all_child_services.empty?
      self.all_child_services(false).each do |service|
        service_providers = service.organization.service_providers_lookup.reject{|x| x.organization_id == self.id}
        if service_providers == []
          has_provider = false
        end
      end
    end

    has_provider
  end

  # Returns all *relevant* service providers for an organization.  Returns this organization's
  # service providers, as well as the service providers on all parents.  If the process_ssrs flag
  # is true at this organization, also returns the service providers of all children.
  def all_service_providers(include_children=true)
    if process_ssrs && include_children
      ServiceProvider.joins(:organization).
        where("(organizations.lft <= ? AND organizations.rgt >= ?) OR (organizations.lft > ? AND organizations.rgt < ?)", lft, rgt, lft, rgt)
    else
      ServiceProvider.joins(:organization).
        where("organizations.lft <= ? AND organizations.rgt >= ?", lft, rgt)
    end.to_a.
      uniq(&:identity_id)
  end

  # Returns all *relevant* super users for an organization.  Returns this organization's
  # super users, as well as the super users on all parents.  If the process_ssrs flag
  # is true at this organization, also returns the super users of all children.
  def all_super_users
    if process_ssrs
      SuperUser.joins(:organization).
        where("(organizations.lft <= ? AND organizations.rgt >= ?) OR (organizations.lft > ? AND organizations.rgt < ?)", lft, rgt, lft, rgt)
    else
      SuperUser.joins(:organization).
        where("organizations.lft <= ? AND organizations.rgt >= ?", lft, rgt)
    end.to_a.
      uniq(&:identity_id)
  end

  def get_available_statuses
    tmp_available_statuses = self.available_statuses.reject{|status| status.new_record?}
    statuses = []
    if tmp_available_statuses.empty?
      self.parents.each do |parent|
        if !parent.available_statuses.empty?
          statuses = AVAILABLE_STATUSES.select{|k,v| parent.available_statuses.map(&:status).include? k}
          return statuses
        end
      end
    else
      statuses = AVAILABLE_STATUSES.select{|k,v| tmp_available_statuses.map(&:status).include? k}
    end
    if statuses.empty?
      statuses = AVAILABLE_STATUSES.select{|k,v| DEFAULT_STATUSES.include? k}
    end
    statuses
  end

  def self.find_all_by_available_status status
    Organization.all.select{|x| x.get_available_statuses.keys.include? status}
  end

  def has_tag? tag
    if self.tag_list.include? tag
      return true
    elsif parent
      self.parent.has_tag? tag
    else
      return false
    end
  end

  private

  def self.authorized_child_organizations(org_ids)
    org_ids = org_ids.flatten.compact
    if org_ids.empty?
      []
    else
      orgs = Organization.where(parent_id: org_ids)
      orgs | authorized_child_organizations(orgs.pluck(:id))
    end
  end

  def compute_lft_and_rgt
    if parent_id_changed? || !id
      new_parent = Organization.find_by(id: parent_id)
      if new_parent
        self.lft = new_parent.rgt
        self.rgt = self.lft + 1
        Organization.where('rgt >= ?', self.lft).update_all('rgt = rgt + 2')
        Organization.where('lft > ?', self.lft).update_all('lft = lft + 2')
      else
        last_rgt = Organization.maximum(:rgt) || 0
        self.lft = last_rgt + 1
        self.rgt = self.lft + 1
      end
    end
  end
end

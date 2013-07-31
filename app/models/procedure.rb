class Procedure < ActiveRecord::Base
  audited

  belongs_to :appointment
  belongs_to :visit
  belongs_to :line_item
  attr_accessible :appointment_id
  attr_accessible :visit_id
  attr_accessible :line_item_id
  attr_accessible :completed
  attr_accessible :quantity

  def required?
    self.visit.to_be_performed?
  end

  def core
    self.line_item.service.organization
  end

  # This method is primarily for setting initial values on the visit calendar in 
  # clinical work fulfillment.
  def default_quantity
    service_quantity = self.quantity
    service_quantity ||= self.visit.research_billing_qty
    service_quantity
  end

  # Totals up a given row on the visit schedule
  def total
    self.default_quantity * self.line_item.per_unit_cost
  end

  def should_be_displayed
    if (self.visit.research_billing_qty && self.visit.research_billing_qty > 0) or (self.visit.insurance_billing_qty && self.visit.insurance_billing_qty > 0)
      return true
    else
      return false
    end
  end
end

class Submission < ActiveRecord::Base
  belongs_to :service
  belongs_to :identity
  has_many :questionnaire_responses
  accepts_nested_attributes_for :questionnaire_responses

  def questionnaire_responses_item_ids
    questionnaire_responses.map(&:item_id)
  end

  def submission_items
    items = []
    questionnaire_responses_item_ids.each do |item_id|
      item = Item.find(item_id)
      items.push(item)
    end
    items
  end
end

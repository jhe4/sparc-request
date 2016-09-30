class Submission < ActiveRecord::Base
  belongs_to :service
  belongs_to :identity
  belongs_to :questionnaire
  has_many :questionnaire_responses, dependent: :destroy
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

  def associated_questionnaire
    first_item_id = questionnaire_responses_item_ids.first
    Item.find(first_item_id).questionnaire_id
  end
end

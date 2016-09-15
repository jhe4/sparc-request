class AdditionalDetails::SubmissionsController < ApplicationController
  layout 'additional_details'
  include AdditionalDetails::StatesHelper

  def show
    @submission = Submission.find(params[:id])
    @questionnaire_responses = @submission.questionnaire_responses
    @items = @submission.submission_items
    respond_to do |format|
      format.js
    end
  end

  def new
    @service = Service.find(params[:service_id])
    @questionnaire = @service.questionnaires.active.first
    @submission = Submission.new
    @submission.questionnaire_responses.build
  end

  def create
    @service = Service.find(params[:service_id])
    @questionnaire = @service.questionnaires.active.first
    @submission = Submission.new(submission_params)
    if @submission.save
      redirect_to service_additional_details_questionnaires_path(@service)
    else
      render :new
    end
  end

  private

  def submission_params
    params.require(:submission).permit!
  end
end

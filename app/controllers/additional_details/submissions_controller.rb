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

  def edit
    @service = Service.find(params[:service_id])
    @submission = Submission.find(params[:id])
    @questionnaire = @service.questionnaires.active.first
  end

  def create
    @service = Service.find(params[:service_id])
    @questionnaire = @service.questionnaires.active.first
    @submission = Submission.new(submission_params)
    if @submission.save
      if params[:send_to_dashboard] == true
        redirect_to dashboard_protocol_path(params[:protocol])
      else
        redirect_to service_additional_details_questionnaires_path(@service)
      end
    else
      render :new
    end
  end

  def update
    @service = Service.find(params[:service_id])
    @submission = Submission.find(params[:id])
    @submission.update_attributes(submission_params)
    respond_to do |format|
      if @submission.save
        format.js
      else
        format.js
      end
    end
  end

  def destroy
    @submission = Submission.find(params[:id])
    @protocol = Protocol.find(params[:protocol_id])
    respond_to do |format|
      if @submission.destroy
        format.js
      else
        format.js
      end
    end
  end

  private

  def submission_params
    params.require(:submission).permit!
  end
end

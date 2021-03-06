class EmailsController < ApplicationController
  before_action :authenticate_user!

  def index
    @emails = current_user.emails.where(visible: true)
  end

  def scheduled
    @emails = current_user.emails.where("visible = ? AND is_sent = ?", true, false)
  end

  def log
    @emails = current_user.emails.where("visible = ? AND is_sent = ?", true, true)
  end

  def create
    hash = post_params()
    hash[:from] = current_user.uid
    @email = current_user.emails.new(hash)

    if @email.save
      if hash[:schedule] == 'now'
        MainMailer.send_email(@email).deliver_now
        @email.update({:is_sent => true})
      end
    else
      render json: { message: "400 Bad Request" }, status: :bad_request
    end
  end

  def update
    @email = current_user.emails.find_by_id(params[:id])

    if @email.nil?
      render json: { message: "Cannot find email" }, status: :not_found
    else
      if @email.is_sent
        render json: { message: "Email has already been sent" }, status: :bad_request
      else
        @email.update(post_params)
      end
    end
  end

  def show
    @email = current_user.emails.find_by_id(params[:id])

    if @email.nil?
      render json: { message: "Cannot find email" }, status: :not_found
    end
  end

  def destroy
    @email = current_user.emails.find_by_id(params[:id])

    if @email.nil?
      render json: { message: "Cannot find email" }, status: :not_found
    else
      if @email.destroy
        render json: { message: "Successfully deleted" }, status: :no_content
      else
        render json: { message: "Unsuccessfully deleted" }, status: :bad_request
      end
    end
  end

  private

  def post_params
    params.require(:email).permit(:title, :to, :schedule, :content, :visible)
  end
end

class TeamsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team, only: %i[show edit update destroy change_owner]

  def index
    @teams = Team.all
  end

  def show
    @working_team = @team
    change_keep_team(current_user, @team)
  end

  def new
    @team = Team.new
  end

  def edit
  end

  def create
    @team = Team.new(team_params)
    @team.owner = current_user
    if @team.save
      @team.invite_member(@team.owner)
      redirect_to @team, notice: I18n.t('views.messages.create_team')
    else
      flash.now[:error] = I18n.t('views.messages.failed_to_save_team')
      render :new
    end
  end

  def update
    if @team.owner == current_user
      if @team.update(team_params)
        redirect_to @team, notice: I18n.t('views.messages.update_team')
      else
        flash.now[:error] = I18n.t('views.messages.failed_to_save_team')
        render :edit
      end
    else
      redirect_to teams_path, notice: "リーダー以外は編集できません。"
    end
  end

  def destroy
    @team.destroy
    redirect_to teams_url, notice: I18n.t('views.messages.delete_team')
  end

  def dashboard
    @team = current_user.keep_team_id ? Team.find(current_user.keep_team_id) : current_user.teams.first
  end

  def change_owner
    #リーダー権限付与
    @team.update(owner_id: params[:owner_id])
    @owner = User.find(@team.owner_id)
    ChangeOwnerMailer.change_owner_mail(@owner).deliver
    redirect_to team_path, notice: '権限を変更しました。'
  end

  private

  def set_team
    @team = Team.friendly.find(params[:id])
  end

  def team_params
    params.fetch(:team, {}).permit %i[name icon icon_cache owner_id keep_team_id]
  end
end

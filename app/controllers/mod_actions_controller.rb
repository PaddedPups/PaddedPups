class ModActionsController < ApplicationController
  respond_to :html, :json

  def index
    @mod_actions = ModAction.includes(:creator).search(search_params).paginate(params[:page], limit: params[:limit])
    respond_with(@mod_actions) do |format|
      format.json do
        render json: @mod_actions, each_serializer: ModActionSerializer
      end
    end
  end

  def show
    @mod_action = ModAction.find(params[:id])
    respond_with(@mod_action) do |fmt|
      fmt.html { redirect_to mod_actions_path(search: { id: @mod_action.id }) }
    end
  end
end

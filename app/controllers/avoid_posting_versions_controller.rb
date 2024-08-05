# frozen_string_literal: true

class AvoidPostingVersionsController < ApplicationController
  respond_to :html, :json

  def index
    @avoid_posting_versions = AvoidPostingVersion.search(search_params).paginate(params[:page], limit: params[:limit])
    respond_with(@avoid_posting_versions)
  end
end

# frozen_string_literal: true

class FavoritePolicy < ApplicationPolicy
  def index?
    unbanned?
  end
end

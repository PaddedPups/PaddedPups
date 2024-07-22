# frozen_string_literal: true

class AddIsDeletedToUserFeedbacks < ActiveRecord::Migration[7.1]
  def change
    add_column(:user_feedbacks, :is_deleted, :boolean, null: false, default: false)
  end
end

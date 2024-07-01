# frozen_string_literal: true

class AddFrameCountToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column(:posts, :framecount, :integer)
    add_column(:posts, :thumbnail_frame, :integer)
  end
end

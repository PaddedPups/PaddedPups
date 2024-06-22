class AddGenderTagCategory < ActiveRecord::Migration[7.1]
  def change
    add_column(:posts, :tag_count_gender, :integer, default: 0, null: false)
  end
end

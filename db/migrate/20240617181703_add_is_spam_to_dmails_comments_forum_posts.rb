# frozen_string_literal: true

class AddIsSpamToDmailsCommentsForumPosts < ActiveRecord::Migration[7.1]
  def change
    add_column(:dmails, :is_spam, :boolean, default: false, null: false)
    add_column(:comments, :is_spam, :boolean, default: false, null: false)
    add_column(:forum_posts, :is_spam, :boolean, default: false, null: false)
  end
end

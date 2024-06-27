# frozen_string_literal: true

class AddWikiPageIdToHelpPages < ActiveRecord::Migration[7.1]
  def change
    add_reference(:help_pages, :wiki_page, foreign_key: true, null: true)
  end
end

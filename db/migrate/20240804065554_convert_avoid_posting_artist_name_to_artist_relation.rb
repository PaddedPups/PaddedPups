# frozen_string_literal: true

class ConvertAvoidPostingArtistNameToArtistRelation < ActiveRecord::Migration[7.1]
  def change
    remove_column(:avoid_postings, :artist_name, :string, null: false)
    remove_column(:avoid_posting_versions, :artist_name, :string, null: false)
    add_reference(:avoid_postings, :artist, null: false, foreign_key: true)
  end
end

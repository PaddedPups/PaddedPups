# frozen_string_literal: true

require "test_helper"

class HelpControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    CurrentUser.user = @user
    as(@user) do
      @wiki = create(:wiki_page, title: "help")
      @help = create(:help_page, wiki_page: @wiki, name: "very_important")
    end
  end

  test "index renders" do
    get help_pages_path
    assert_response :success
  end

  test "index renders for admins" do
    get_auth help_pages_path, create(:admin_user)
    assert_response :success
  end

  test "it loads when the url contains spaces" do
    get help_page_path(id: "very important")
    assert_response :success
  end
end

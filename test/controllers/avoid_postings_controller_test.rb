# frozen_string_literal: true

require "test_helper"

class AvoidPostingsControllerTest < ActionDispatch::IntegrationTest
  context "The avoid postings controller" do
    setup do
      @user = create(:user)
      @owner_user = create(:owner_user)
      CurrentUser.user = @user

      as(@owner_user) do
        @artist = create(:artist)
        @avoid_posting = AvoidPosting.create!(artist_name: @artist.name)
      end
    end

    context "index action" do
      should "render" do
        get_auth avoid_postings_path, @user
        assert_response :success
      end

      should "restrict access" do
        assert_access(User::Levels::ANONYMOUS) { |user| get_auth avoid_postings_path, user }
      end
    end

    context "show action" do
      should "render" do
        get_auth avoid_posting_path(@avoid_posting), @user
        assert_response :success
      end

      should "restrict access" do
        assert_access(User::Levels::ANONYMOUS) { |user| get_auth avoid_posting_path(@avoid_posting), user }
      end
    end

    context "edit action" do
      should "render" do
        get_auth edit_avoid_posting_path(@avoid_posting), @owner_user
        assert_response :success
      end

      should "restrict access" do
        assert_access(User::Levels::OWNER) { |user| get_auth edit_avoid_posting_path(@avoid_posting), user }
      end
    end

    context "create action" do
      should "work" do
        assert_difference("AvoidPosting.count", 1) do
          post_auth avoid_postings_path, @owner_user, params: { avoid_posting: { artist_name: "another_artist" } }
        end

        avoid_posting = AvoidPosting.find_by(artist_name: "another_artist")
        assert_not_nil(avoid_posting)
        assert_redirected_to(avoid_posting_path(avoid_posting))
      end

      should "restrict access" do
        assert_access(User::Levels::OWNER, success_response: :redirect) { |user| post_auth avoid_postings_path, user, params: { avoid_posting: { artist_name: SecureRandom.hex(6) } } }
      end
    end

    context "update action" do
      should "work" do
        assert_difference("ModAction.count", 1) do
          put_auth avoid_posting_path(@avoid_posting), @owner_user, params: { avoid_posting: { details: "test" } }
        end

        assert_redirected_to(avoid_posting_path(@avoid_posting))
        assert_equal("avoid_posting_update", ModAction.last.action)
        assert_equal("test", @avoid_posting.reload.details)
      end

      should "restrict access" do
        assert_access(User::Levels::OWNER, success_response: :redirect) { |user| put_auth avoid_posting_path(@avoid_posting), user, params: { avoid_posting: { details: "test"} } }
      end
    end

    context "when renaming" do
      should "rename artist" do
        assert_difference("ModAction.count", 2) do
          put_auth avoid_posting_path(@avoid_posting), @owner_user, params: { avoid_posting: { artist_name: "another_artist", rename_artist: true } }
        end

        assert_redirected_to(avoid_posting_path(@avoid_posting))
        assert_same_elements(%w[avoid_posting_update artist_rename], ModAction.last(2).map(&:action))
        assert_equal("another_artist", @avoid_posting.reload.artist_name)
        assert_equal("another_artist", @artist.reload.name)
      end

      should "not rename artist if new name already exists" do
        name = @artist.name
        new_artist = create(:artist)
        put_auth avoid_posting_path(@avoid_posting), @owner_user, params: { avoid_posting: { artist_name: new_artist.name, rename_artist: true } }

        assert_equal(name, @avoid_posting.reload.artist_name)
        assert_equal(name, @artist.reload.name)
      end

      should "not rename artist if rename_artist=false" do
        name = @artist.name
        assert_difference("ModAction.count", 1) do
          put_auth avoid_posting_path(@avoid_posting), @owner_user, params: { avoid_posting: { artist_name: "another_artist", rename_artist: false } }
        end

        assert_redirected_to(avoid_posting_path(@avoid_posting))
        assert_equal("avoid_posting_update", ModAction.last.action)
        assert_equal("another_artist", @avoid_posting.reload.artist_name)
        assert_equal(name, @artist.reload.name)
      end
    end

    context "deactivate action" do
      should "work" do
        assert_difference("ModAction.count", 1) do
          put_auth deactivate_avoid_posting_path(@avoid_posting), @owner_user
        end
  
        assert_equal(false, @avoid_posting.reload.is_active?)
        assert_equal("avoid_posting_deactivate", ModAction.last.action)
      end

      should "restrict access" do
        assert_access(User::Levels::OWNER, success_response: :redirect) { |user| put_auth deactivate_avoid_posting_path(@avoid_posting), user }
      end
    end

    context "reactivate action" do
      should "work" do
        @avoid_posting.update_column(:is_active, false)
  
        assert_difference("ModAction.count", 1) do
          put_auth reactivate_avoid_posting_path(@avoid_posting), @owner_user
        end
  
        assert_equal(true, @avoid_posting.reload.is_active?)
        assert_equal("avoid_posting_reactivate", ModAction.last.action)
      end
  
      should "restrict access" do
        assert_access(User::Levels::OWNER, success_response: :redirect) { |user| put_auth reactivate_avoid_posting_path(@avoid_posting), user }
      end
    end

    context "destroy action" do
      should "work" do
        assert_difference("ModAction.count", 1) do
          delete_auth avoid_posting_path(@avoid_posting), @owner_user
        end
  
        assert_nil(AvoidPosting.find_by(id: @avoid_posting.id))
        assert_equal("avoid_posting_delete", ModAction.last.action)
      end

      should "restrict access" do
        assert_access(User::Levels::OWNER, success_response: :redirect) { |user| delete_auth avoid_posting_path(@avoid_posting), user }
      end
    end
  end
end

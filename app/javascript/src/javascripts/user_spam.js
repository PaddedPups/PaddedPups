import Comment from "./comments.js";
import DText from "./dtext.js";
import ForumPost from "./forum_posts.js";
import Utility from "./utility.js";

export default class UserSpam {
  static initialize_click_handlers() {
    function handle(event, action) {
      event.preventDefault();
      const $target = $(event.target);
      const type = $target.data("item-route");
      const id = $target.data("item-id");

      $.ajax({
        type: "PUT",
        url: `/${type}/${id}/mark_${action}.json`
      }).done(data => {
        $target.closest("article.comment, article.forum-post").replaceWith(data.html);
        $(window).trigger("e621:add_deferred_posts", data.posts);

        UserSpam.reinitialize_click_handlers();
        Comment.reinitialize_all();
        ForumPost.reinitialize_all();
        DText.initialize_all_inputs();
      }).fail(data => {
        Utility.error(`Failed to mark as ${action.replaceAll("_", " ")}.`);
      });
    }
    $(".item-mark-spam").on("click", event => handle(event, "spam"));
    $(".item-mark-not-spam").on("click", event => handle(event, "not_spam"));
  }

  static reinitialize_click_handlers() {
    $(".item-mark-spam").off("click");
    $(".item-mark-not-spam").off("click");
    this.initialize_click_handlers();
  }
}

$(() => {
  UserSpam.initialize_click_handlers();
});

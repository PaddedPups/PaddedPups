# frozen_string_literal: true

class PostImageSampleJob < ApplicationJob
  queue_as :samples
  sidekiq_options lock: :until_executed, lock_args_method: :lock_args, retry: 3

  def self.lock_args(args)
    [args[0]]
  end

  def perform(id)
    post = Post.find(id)
    post.regenerate_image_samples!
  end
end

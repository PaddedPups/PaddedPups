# frozen_string_literal: true

class Pool < ApplicationRecord
  class RevertError < StandardError
  end

  array_attribute :post_ids, parse: %r{(?:https://paddedpups.xyz/posts/)?(\d+)}i, cast: :to_i
  belongs_to_creator

  validates :name, uniqueness: { case_sensitive: false, if: :name_changed? }
  validates :name, length: { minimum: 1, maximum: 250 }
  validates :description, length: { maximum: FemboyFans.config.pool_descr_max_size }
  validate :user_not_create_limited, on: :create
  validate :user_not_limited, on: :update, if: :limited_attribute_changed?
  validate :user_not_posts_limited, on: :update, if: :post_ids_changed?
  validate :validate_name, if: :name_changed?
  validate :updater_can_remove_posts
  validate :validate_number_of_posts
  before_validation :normalize_post_ids
  before_validation :normalize_name
  after_create :synchronize!
  before_destroy :remove_all_posts
  after_destroy :log_delete
  after_save :create_version
  after_save :synchronize, if: :saved_change_to_post_ids?

  attr_accessor :skip_sync

  def limited_attribute_changed?
    name_changed? || description_changed? || is_active_changed?
  end

  module SearchMethods
    def for_user(id)
      where("pools.creator_id = ?", id)
    end

    def any_artist_name_matches(regex)
      where(id: Pool.from("unnest(artist_names) AS artist_name").where("artist_name ~ ?", regex))
    end

    def any_artist_name_like(name)
      where(id: Pool.from("unnest(artist_names) AS artist_name").where("artist_name LIKE ?", name.to_escaped_for_sql_like))
    end

    def selected_first(current_pool_id)
      return where("true") if current_pool_id.blank?
      current_pool_id = current_pool_id.to_i
      reorder(Arel.sql("(case pools.id when #{current_pool_id} then 0 else 1 end), pools.name"))
    end

    def default_order
      order(updated_at: :desc)
    end

    def search(params)
      q = super

      if params[:name_matches].present?
        q = q.attribute_matches(:name, normalize_name(params[:name_matches]), convert_to_wildcard: true)
      end

      q = q.any_artist_name_matches(params[:any_artist_name_matches]) if params[:any_artist_name_matches].present?
      q = q.any_artist_name_like(params[:any_artist_name_like]) if params[:any_artist_name_like].present?
      q = q.attribute_matches(:description, params[:description_matches])
      q = q.where_user(:creator_id, :creator, params)
      q = q.attribute_matches(:is_active, params[:is_active])

      case params[:order]
      when "name"
        q = q.order("pools.name")
      when "created_at"
        q = q.order("pools.created_at desc")
      when "post_count"
        q = q.order(Arel.sql("cardinality(post_ids) desc")).default_order
      else
        q = q.apply_basic_order(params)
      end

      q
    end
  end

  extend SearchMethods

  def user_not_create_limited
    allowed = creator.can_pool_with_reason
    if allowed != true
      errors.add(:creator, User.throttle_reason(allowed))
      return false
    end
    true
  end

  def user_not_limited
    allowed = CurrentUser.can_pool_edit_with_reason
    if allowed != true
      errors.add(:updater, User.throttle_reason(allowed))
      return false
    end
    true
  end

  def user_not_posts_limited
    allowed = CurrentUser.can_pool_post_edit_with_reason
    if allowed != true
      errors.add(:updater, "#{User.throttle_reason(allowed)}: updating unique pools posts")
      return false
    end
    true
  end

  def self.name_to_id(name)
    if name =~ /\A\d+\z/
      name.to_i
    else
      Pool.where("lower(name) = ?", name.downcase.tr(" ", "_")).pick(:id).to_i
    end
  end

  def self.normalize_name(name)
    name.gsub(/[_[:space:]]+/, "_").gsub(/\A_|_\z/, "")
  end

  def self.find_by_name(name)
    if name =~ /\A\d+\z/
      where("pools.id = ?", name.to_i).first
    elsif name
      where("lower(pools.name) = ?", normalize_name(name).downcase).first
    end
  end

  def versions
    PoolVersion.where("pool_id = ?", id).order("id asc")
  end

  def normalize_name
    self.name = Pool.normalize_name(name)
  end

  def pretty_name
    name.tr("_", " ")
  end

  def normalize_post_ids
    valid = Post.where(id: post_ids.uniq).select(:id).pluck(:id)
    self.post_ids = post_ids.uniq.select { |id| valid.include?(id) }
  end

  def revert_to!(version)
    if id != version.pool_id
      raise(RevertError, "You cannot revert to a previous version of another pool.")
    end

    self.post_ids = version.post_ids
    self.name = version.name
    self.description = version.description
    save
  end

  def contains?(post_id)
    post_ids.include?(post_id)
  end

  def page_number(post_id)
    post_ids.find_index(post_id).to_i + 1
  end

  def deletable_by?(user)
    user.is_janitor?
  end

  def validate_number_of_posts
    post_ids_before = post_ids_before_last_save || post_ids_was
    added = post_ids - post_ids_before
    return if added.empty?
    max = FemboyFans.config.pool_post_limit(CurrentUser.user)
    if post_ids.size > max
      errors.add(:base, "Pools can only have up to #{ActiveSupport::NumberHelper.number_to_delimited(max)} posts each")
      false
    else
      true
    end
  end

  def add!(post)
    return if post.nil?
    return if post.id.nil?
    return if contains?(post.id)

    with_lock do
      reload
      self.skip_sync = true
      update(post_ids: post_ids + [post.id])
      raise(ActiveRecord::Rollback) unless valid?
      update_artists(post, :add)
      self.skip_sync = false
      post.add_pool!(self)
      post.save
    end
  end

  def add(id)
    return if id.nil?
    return if contains?(id)

    post_ids << id
  end

  def remove!(post)
    return unless contains?(post.id)
    return unless CurrentUser.user.can_remove_from_pools?

    with_lock do
      reload
      self.skip_sync = true
      update(post_ids: post_ids - [post.id])
      raise(ActiveRecord::Rollback) unless valid?
      update_artists(post, :remove)
      self.skip_sync = false
      post.remove_pool!(self)
      post.save
    end
  end

  def posts
    Post.joins("left join pools on posts.id = ANY(pools.post_ids)").where(pools: { id: id }).order(Arel.sql("array_position(pools.post_ids, posts.id)"))
  end

  def artists
    return artist_names if Cache.fetch("pa:#{id}", expires_in: 12.hours) == "1"
    names = posts.flat_map(&:artist_tags).map(&:name).reject { |name| FemboyFans.config.artist_exclusion_tags.include?(name) }
    update_column(:artist_names, names)
    self.artist_names = names
    Cache.write("pa:#{id}", "1", expires_in: 12.hours)
    artist_names
  end

  def update_artists(post, action)
    arttags = post.artist_tags.map(&:name)
    current = artists
    case action
    when :add
      Cache.delete("pa:#{id}") unless (arttags - current).empty?
    else
      # We don't know if any other posts have the artist tags when removing a post, so we're forced to always clear the cache
      Cache.delete("pa:#{id}")
    end
  end

  def synchronize
    return if skip_sync == true
    post_ids_before = post_ids_before_last_save || post_ids_was
    added = post_ids - post_ids_before
    removed = post_ids_before - post_ids

    Post.where(id: added).find_each do |post|
      update_artists(post, :add)
      post.add_pool!(self)
      post.save
    end

    Post.where(id: removed).find_each do |post|
      update_artists(post, :remove)
      post.remove_pool!(self)
      post.save
    end
  end

  def synchronize!
    synchronize
    save if will_save_change_to_post_ids?
  end

  def remove_all_posts
    with_lock do
      transaction do
        Post.where(id: post_ids).find_each do |post|
          post.remove_pool!(self)
          post.save
        end
      end
    end
  end

  def post_count
    post_ids.size
  end

  def first_post?(post_id)
    post_id == post_ids.first
  end

  def last_post?(post_id)
    post_id == post_ids.last
  end

  # XXX finds wrong post when the pool contains multiple copies of the same post (#2042).
  def previous_post_id(post_id)
    return nil if first_post?(post_id) || !contains?(post_id)

    n = post_ids.index(post_id) - 1
    post_ids[n]
  end

  def next_post_id(post_id)
    return nil if last_post?(post_id) || !contains?(post_id)

    n = post_ids.index(post_id) + 1
    post_ids[n]
  end

  def cover_post
    Post.find_by(id: post_ids.first)
  end

  def create_version(updater: CurrentUser.user, updater_ip_addr: CurrentUser.ip_addr)
    PoolVersion.queue(self, updater, updater_ip_addr)
  end

  def last_page
    (post_count / CurrentUser.user.per_page.to_f).ceil
  end

  def method_attributes
    super + %i[artists creator_name post_count]
  end

  def validate_name
    case name
    when /\A(any|none)\z/i
      errors.add(:name, "cannot be any of the following names: any, none")
    when /\*/
      errors.add(:name, "cannot contain asterisks")
    when ""
      errors.add(:name, "cannot be blank")
    when /\A[0-9]+\z/
      errors.add(:name, "cannot contain only digits")
    when /,/
      errors.add(:name, "cannot contain commas")
    when /(__|--|  )/
      errors.add(:name, "cannot contain consecutive underscores, hyphens or spaces")
    end
  end

  def updater_can_remove_posts
    removed = post_ids_was - post_ids
    if removed.any? && !CurrentUser.user.can_remove_from_pools?
      errors.add(:base, "You cannot removes posts from pools within the first week of sign up")
    end
  end

  module LogMethods
    def log_delete
      ModAction.log!(:pool_delete, self, pool_name: name, user_id: creator_id)
    end
  end

  include LogMethods
end

# == Schema Information
#
# Table name: users
#
#  id                         :uuid             not null, primary key
#  nickname                   :string           not null
#  image_url                  :string
#  bio                        :string
#  description                :text
#  score                      :integer          default("100"), not null
#  role                       :string           default("regular"), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  random_fav_topic           :boolean          default("false"), not null
#  random_fav_item_types      :string
#  referrer                   :string
#  unsubscribe                :boolean          default("false"), not null
#  has_used_browser_extension :boolean          default("false"), not null
#  has_used_embed             :boolean          default("false"), not null
#  tiddlywiki_url             :string
#  theme                      :string
#

require 'json'

class User < ApplicationRecord
	validates :nickname, presence: true
	validates :nickname, exclusion: { in: %w(learnawesome admin root), message: "%{value} is reserved." }, if: Proc.new { |a| Rails.env.production? }

	validates_length_of :nickname, in: 4..30, allow_blank: false
	validates_length_of :bio, maximum: 140
	validates_length_of :description, maximum: 400

	validates_format_of :nickname, with: /\A[a-zA-Z][a-zA-Z0-9\_.\-]+\Z/

	has_many :user_topics, dependent: :destroy, inverse_of: :user
	has_many :reviews, dependent: :destroy, inverse_of: :user
	has_many :submissions, class_name: "Item"

	has_many :from_user_relations, foreign_key: :from_user_id, class_name: "UserUserRelation", dependent: :destroy
	has_many :following, through: :from_user_relations, source: :to_user

	has_many :to_user_relations, foreign_key: :to_user_id, class_name: "UserUserRelation", dependent: :destroy
	has_many :followers, through: :to_user_relations, source: :from_user

	has_many :collections, dependent: :destroy, inverse_of: :user
	has_many :flash_cards, dependent: :destroy, inverse_of: :user
	has_many :decks, dependent: :destroy, inverse_of: :user
	has_many :social_logins, dependent: :destroy, inverse_of: :user

	has_many :activity_pub_followers, dependent: :destroy, inverse_of: :user

	has_many :group_members, dependent: :destroy, inverse_of: :user
	has_many :groups, through: :group_members

	has_many :recommendations

	has_many :user_levels

	after_create :update_points
	after_create :create_default_deck

	def rocketchat_username
		self.nickname + "-" + self.id.to_s[0..4]
	end

	def rocketchat_password
		Digest::SHA256.hexdigest(self.id.to_s + ENV['ROCKETCHAT_SALT'])[0..16]
	end

	def set_rocketchat_avatar
		chat_server = 'https://chat.learnawesome.org'
		# https://docs.rocket.chat/api/rest-api/methods/users/setavatar
		HTTParty.post(
			chat_server + '/api/v1/users.setAvatar', 
			body: {
				username: self.rocketchat_username,
				avatarUrl: self.image_url
			}, 
			headers: {'X-Auth-Token' => ENV['ROCKETCHAT_ADMIN_AUTHTOKEN'], 'X-User-Id' => ENV['ROCKETCHAT_ADMIN_USERID']}
		)
	end

	def get_rocketchat_userinfo
		chat_server = 'https://chat.learnawesome.org'
		# https://docs.rocket.chat/api/rest-api/methods/users/info
		HTTParty.get(
			chat_server + '/api/v1/users.info', 
			query: {username: self.rocketchat_username}, 
			headers: {'X-Auth-Token' => ENV['ROCKETCHAT_ADMIN_AUTHTOKEN'], 'X-User-Id' => ENV['ROCKETCHAT_ADMIN_USERID']}
		)
	end

	def create_or_login_rocketchat
		return unless self.persisted?
		return unless self.email.present?
		# See if it has been persisted in db
		return self.rocketchat_logintoken if self.rocketchat_logintoken.present?

		userinfo_resp = self.get_rocketchat_userinfo

		if userinfo_resp.code == 200 && JSON.parse(userinfo_resp.body)["success"]
			# Found user
		else
			# create if user does not exist: https://docs.rocket.chat/api/rest-api/methods/users/create
			resp = HTTParty.post(
				chat_server + '/api/v1/users.create', 
				body: {
					username: self.rocketchat_username,
					name: self.rocketchat_username,
					email: self.email,
					password: self.rocketchat_password,
					verified: true
				}, 
				headers: {'X-Auth-Token' => ENV['ROCKETCHAT_ADMIN_AUTHTOKEN'], 'X-User-Id' => ENV['ROCKETCHAT_ADMIN_USERID']}
			)

			self.set_rocketchat_avatar rescue nil
		end

		# now get login token (and persist it?): https://docs.rocket.chat/api/rest-api/methods/authentication/login
		resp = HTTParty.post(
			chat_server + '/api/v1/login', 
			body: {user: self.email, password: self.rocketchat_password}, 
			headers: {'X-Auth-Token' => ENV['ROCKETCHAT_ADMIN_AUTHTOKEN'], 'X-User-Id' => ENV['ROCKETCHAT_ADMIN_USERID']}
		)
		if resp.code == 200 && JSON.parse(userinfo_resp.body)["success"]
			self.rocketchat_logintoken = JSON.parse(resp.body)["data"]["authToken"]
			self.save
		end
		self.rocketchat_logintoken
	end

	def to_param
		self.id.to_s.split("-").first + "-" + self.nickname.to_s.parameterize
	end

	def self.from_param(slug)
		# self.where(id: id.to_s.split("-")[0..4].join("-")).first
		id_without_slug = slug.split("-").first
		# first treat slug as uuid, then fallback as uuid-prefix, both with an optional suffix
		User.where(id: slug.to_s.split("-")[0..4].join("-")).first || self.where("users.id::varchar LIKE '#{id_without_slug}%'").first
	end

	def self.lookup_all_by_email(email)
		SocialLogin.all.select(:user_id, :auth0_info).select { |sl| sl.email == email }.map(&:user)
	end

	def avatar_image
		self.image_url
	end

	def create_default_deck
		self.decks.create(name: 'default deck')
	end

	def update_points
		user = User.where("CAST (id AS TEXT) LIKE '%#{self.referrer}%'").first
		UserPointsService.call(user) if user.present?
	end

	def notifications
		followers = UserUserRelation.where(to_user: self).all
		following = UserUserRelation.where(from_user: self).all
		return followers.map { |f|
			Notification.new(
				headline: "@#{f.from_user.nickname}",
				msg: "started following you",
				image: f.from_user.avatar_image,
				target: f.from_user,
				date: f.created_at.to_date
		)} + following.map { |f|
			Notification.new(
				headline: "You",
				msg: "started following @#{f.to_user.nickname}",
				image: self.avatar_image,
				target: f.to_user,
				date: f.created_at.to_date
		)} + [ Notification.new(
				headline: "LearnAwesome",
				msg: "invites you to learners community",
				image: "/favicon.png",
				target: "https://gitter.im/learn-awesome/community",
				date: "2019-11-01"
		)]
	end

	def fav_topics
		user_topics.map(&:topic)
	end

	def is_admin?
		self.role == "admin"
	end

	def is_tester?
		self.is_admin? || (self.role == 'tester')
	end

	def get_reviews(item_type_id, status, quality = nil, min_quality_score = 0)
		results = self.reviews
		if status.present?
			results = results.where(status: status)
		end

		if quality and min_quality_score and Review::SCORE_TYPES.include?(quality)
			results = results.where(quality: quality).where("? > ?", "#{quality}_score", min_quality_score)
		end

		results = results.all.to_a

		if item_type_id.present?
			results = results.select { |r| r.item.item_type_id == item_type_id }
		end
		return results
	end

	def invited
		User.where(referrer: self.id.to_s.split("-").first)
	end

	def self.core_devs
		User.where(role: "admin").all.map(&:id)
	end

	def email
		self.social_logins.map(&:email).compact.uniq.first
	end

	def is_core_dev?
		Rails.env.development? or User.core_devs.include?(self.id)
	end

	def can_combine_items?
		Rails.env.development? or self.score.to_i >= 5000
	end

	def can_merge_topic?
		Rails.env.development? or self.score.to_i >= 20000
	end

	def can_edit_topic?
		Rails.env.development? or ['9f99ebd6-cf88-445c-ac1c-2d9243095264', '87d3116b-07b2-42dd-abae-85382f8b1aa3'].include?(self.id) or self.score.to_i >= 20000
	end

	def can_delete_topic?
		Rails.env.development? or ['9f99ebd6-cf88-445c-ac1c-2d9243095264', '87d3116b-07b2-42dd-abae-85382f8b1aa3'].include?(self.id) or self.score.to_i >= 20000
	end

	def can_wiki_update_topic?
		Rails.env.development? or self.score.to_i >= 20000
	end

	def can_see_metrics?
		Rails.env.development? or self.score.to_i >= 5000
	end

	def can_modify_recommendations?
		return false if self.score < 50000
		return false unless self.is_core_dev?
		return true
	end

	def can_add_syllabus?
		Rails.env.development? or self.score.to_i >= 20000
	end

	def self.learnawesome
		@la_user ||= User.find_by_nickname('learnawesome')
	end

	def activitypub_id
		id.to_s.gsub("-","_")
	end

	def activitypub_username
		"#{activitypub_id}@learnawesome.org"
	end

	def webfinger_json
		{
			subject: "acct:#{self.activitypub_id}@learnawesome.org",
			links: [
				{
					rel: "self",
					type: "application/activity+json",
					href: Rails.application.routes.url_helpers.actor_user_url(self)
				}
			]
		}
	end

	def actor_json
		# For ActivityPub
		{
			"@context": [
				"https://www.w3.org/ns/activitystreams",
				"https://w3id.org/security/v1"
			],

			"id": Rails.application.routes.url_helpers.actor_user_url(self),
			"type": "Person",
			"preferredUsername": self.activitypub_id.to_s,
			"name": "#{self.nickname} on learnawesome.org",
			"summary": self.bio.to_s,
			"icon": [
			    self.avatar_image.to_s
			  ],

			"inbox": Rails.application.routes.url_helpers.inbox_user_url(self),
			"outbox": Rails.application.routes.url_helpers.outbox_user_url(self, format: :json),

			"followers": Rails.application.routes.url_helpers.ap_followers_user_url(self),
			"following": Rails.application.routes.url_helpers.ap_following_user_url(self),

			"publicKey": {
				"id": (Rails.application.routes.url_helpers.actor_user_url(self) + "#main-key"),
				"owner": Rails.application.routes.url_helpers.actor_user_url(self),
				"publicKeyPem": ENV['ACTIVITYPUB_PUBKEY'].to_s
			}
		}
	end

	def ap_url
		Rails.application.routes.url_helpers.actor_user_url(self)
	end

	def ap_followers_json(request, params)
		if params[:page].blank?
			{
			"@context": "https://www.w3.org/ns/activitystreams",
			"id": request.original_url,
			"type": "OrderedCollection",
			"totalItems": (self.followers.count + self.activity_pub_followers.count),
			"first": request.original_url + "?page=1"
			}
		else
			{
				"@context": "https://www.w3.org/ns/activitystreams",
				"id": request.original_url,
				"type": "OrderedCollectionPage",
				"totalItems": (self.followers.count + self.activity_pub_followers.count),
				"next": Rails.application.routes.url_helpers.ap_followers_user_url(self) + "?page=#{params[:page].to_i + 1}",
				"partOf": Rails.application.routes.url_helpers.ap_followers_user_url(self),
				"orderedItems": (self.followers.order(:created_at) + self.activity_pub_followers.order(:created_at)).drop((params[:page].to_i - 1) * 12).take(12).map(&:ap_url)
			}
		end
	end

	def outbox_json(request, params)
		if params[:page].blank?
			{
			"@context": "https://www.w3.org/ns/activitystreams",
			"id": request.original_url,
			"type": "OrderedCollection",
			"totalItems": self.reviews.count,
			"first": request.original_url + "?page=1"
			}
		else
			{
				"@context": "https://www.w3.org/ns/activitystreams",
				"id": request.original_url,
				"type": "OrderedCollectionPage",
				"totalItems": self.reviews.count,
				"next": Rails.application.routes.url_helpers.outbox_user_url(self, format: :json) + "?page=#{params[:page].to_i + 1}",
				"partOf": Rails.application.routes.url_helpers.outbox_user_url(self, format: :json),
				"orderedItems": self.reviews.order("created_at DESC").drop((params[:page].to_i - 1) * 20).take(20).map(&:activity_pub)
			}
		end
	end

	def ap_following_json(request, params)
		if params[:page].blank?
			{
			"@context": "https://www.w3.org/ns/activitystreams",
			"id": request.original_url,
			"type": "OrderedCollection",
			"totalItems": self.following.count,
			"first": request.original_url + "?page=1"
			}
		else
			{
				"@context": "https://www.w3.org/ns/activitystreams",
				"id": request.original_url,
				"type": "OrderedCollectionPage",
				"totalItems": self.following.count,
				"next": Rails.application.routes.url_helpers.ap_following_user_url(self) + "?page=#{params[:page].to_i + 1}",
				"partOf": Rails.application.routes.url_helpers.ap_following_user_url(self),
				"orderedItems": self.followers.order(:created_at).drop((params[:page].to_i - 1) * 12).take(12).map(&:ap_url)
			}
		end
	end

	def add_to_inbox!(all_headers, body)
	  # keyId="https://learnawesome.org/users/8a16a2e4-dcb7-4167-a2a2-51d3af9d1613/actor#main-key",headers="(request-target) host date",signature="..."
	  # {'Host': 'learnawesome.org', 'Date': '2019-11-14T12:39:31+05:30'}
	  inbox_path = Rails.application.routes.url_helpers.inbox_user_path(self)
	  actor_url = Rails.application.routes.url_helpers.actor_user_url(self)
	  body_hash = JSON.parse(body)

	  if body_hash["object"] == actor_url and ActivityPub.verify(nil, all_headers, inbox_path)
	  	if body_hash["type"] == "Follow" # Do this check first
	  		Rails.logger.info "New follow from ActivityPub for user #{self.id}"
	  		afp = self.activity_pub_followers.create!(metadata: body)
	  		# Send Accept response
			ActivityPubFollowAcceptedJob.perform_later(afp.id, 'user')
			return true, "Follow accepted"
		elsif body_hash["type"] == "Unfollow" # Do this check first
			Rails.logger.info "Unfollow request from ActivityPub for #{self.id}: #{body_hash.inspect}"
			return false, "Unfollow not yet implemented for #{self.id}: #{body_hash.inspect}"
		else
			Rails.logger.info "Unknown ActivityType for #{self.id}: #{body_hash.inspect}"
			return false, "Unknown ActivityType for #{self.id}: #{body_hash.inspect}"  
		end
	  elsif body_hash["type"] == "Delete"
		# a user has been deleted
		apf = self.activity_pub_followers.select { |x| x.object == body_hash["object"] }.first
		if apf
			apf.destroy
			return true, "Follower #{apf.object} deleted"
		else
			return true, "APF does not exist"
		end
	  elsif body_hash["type"] == "Undo"
		return true, "Undo is not implemented"
	  else
	    return false, "Request signature could not be verified: #{all_headers.inspect} body=#{body}"
	  end
	end

	def theme_variant
		if self.theme.blank?
			:tailwind
		else
			self.theme.to_sym
		end
	end

	def merge_account(old_user_id)
		Rails.logger.info "Merging accounts: #{old_user_id} into #{self.id}"
		# move reviews, items, points, followers etc
		# Take care not to violate unique constraints while merging things
		raise "Merge account error" unless self.persisted?

		Topic.where(user_id: old_user_id).update_all(user_id: self.id) rescue nil

		UserTopic.where(user_id: old_user_id).each do |r|
		r.update!(user_id: self.id) rescue nil
		end

		Review.where(user_id: old_user_id).each do |r|
		r.update!(user_id: self.id) rescue nil
		end
		Item.where(user_id: old_user_id).update_all(user_id: self.id) rescue nil

		UserUserRelation.where(from_user_id: old_user_id).each do |uu|
		uu.update!(from_user_id: self.id) rescue nil
		end

		UserUserRelation.where(to_user_id: old_user_id).each do |uu|
		uu.update!(to_user_id: self.id) rescue nil
		end

		Collection.where(user_id: old_user_id).update_all(user_id: self.id) rescue nil

		Deck.where(user_id: old_user_id).each do |deck|
			deck.update!(user_id: self.id, name: "#{deck.name} (copied from #{old_user_id})") rescue nil
		end

		FlashCard.where(user_id: old_user_id).update_all(user_id: self.id) rescue nil

		User.find(old_user_id).destroy # clean up
		UserPointsService.call(self)
	end

	def self.discover
		User.order('RANDOM()').first
	end

	def onboarding
		# Rails.cache.fetch("user_onboarding_#{self.id}", expires_in: 30.minutes) do
		@onboarding ||= {
				first_follow_topic: [self.user_topics.count > 0, Rails.application.routes.url_helpers.topics_path],
				first_review: [self.reviews.count > 0, Rails.application.routes.url_helpers.topics_path],
				profile_bio: [self.bio.to_s.present?, Rails.application.routes.url_helpers.edit_user_url(self)],
				installed_browser_extension: [self.has_used_browser_extension, "/browser_addon"],
				first_item: [self.submissions.count > 0, Rails.application.routes.url_helpers.user_url(self)],
				first_user_follow: [self.following.count > 0, "/users"],
				first_referral: [self.invited.count > 0, Rails.application.routes.url_helpers.settings_user_path(self)],
				first_group: [self.groups.count > 0, Rails.application.routes.url_helpers.user_groups_path(self)],
				first_collection: [self.collections.count > 0, Rails.application.routes.url_helpers.user_collections_path(self)],
				embed_reviews: [self.has_used_embed, Rails.application.routes.url_helpers.user_url(self)],
				first_flashcard: [self.flash_cards.count > 0, "/flash_cards/practice"],
				first_activitypub_follower: [self.activity_pub_followers.count > 0, Rails.application.routes.url_helpers.user_path(self)],
				profile_score: [self.score >= 150, Rails.application.routes.url_helpers.user_url(self)],
				social_login: [self.social_logins.count > 1, Rails.application.routes.url_helpers.settings_user_path(self)],
				join_chat: [false, "/join_slack"]
			}
		# end
	end

	def onboarding_percentage
		(self.onboarding.keys.select { |k| self.onboarding[k].first }.size * 100.0 / self.onboarding.keys.size).round
	end

	def self.onboarding_steps
		[
			[:first_follow_topic, "Follow your first favorite topic"],
			[:first_review, "Add your first review"],
			[:profile_bio, "Update your bio in profile"],
			[:installed_browser_extension, "Install the browser extension"],
			[:first_item, "Add your first link"],
			[:first_user_follow, "Follow another user"],
			[:first_referral, "Invite a friend"],
			[:first_group, "Create or join a group"],
			[:first_collection, "Create your first collection"],
			[:embed_reviews, "Embed your reviews on your blog or other sites"],
			[:first_flashcard, "Create your first flashcard"],
			[:profile_score, "Reach a profile score of 150"],
			[:join_chat, "Join our community Slack"],
			[:social_login, "Connect another social network"],
			[:first_activitypub_follower, "Get a follower on ActivityPub or Mastodon"]
		]
	end
end

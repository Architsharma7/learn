# == Schema Information
#
# Table name: items
#
#  id                    :uuid             not null, primary key
#  name                  :string           not null
#  item_type_id          :string           not null
#  estimated_time        :integer
#  time_unit             :string           default("minutes"), not null
#  required_expertise    :integer
#  idea_set_id           :uuid             not null
#  user_id               :uuid             not null
#  year                  :integer
#  image_url             :string
#  inspirational_score   :decimal(3, 2)
#  educational_score     :decimal(3, 2)
#  challenging_score     :decimal(3, 2)
#  entertaining_score    :decimal(3, 2)
#  visual_score          :decimal(3, 2)
#  interactive_score     :decimal(3, 2)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  level                 :string
#  description           :text
#  metadata              :json             not null
#  page_count            :integer
#  goodreads_rating      :decimal(3, 2)
#  amazon_rating         :decimal(3, 2)
#  isbn                  :string
#  isbn13                :string
#  cost                  :decimal(8, 2)
#  language              :string
#  overall_score         :decimal(3, 2)
#  protected_description :text
#  is_approved           :boolean          default(FALSE), not null
#
require 'uri'
require 'nokogiri'
require 'open-uri'
require 'redcarpet'

class Item < ApplicationRecord
  include ActionView::Helpers::TextHelper

  belongs_to :idea_set, inverse_of: :items
  has_many :topic_idea_sets, through: :idea_set
  has_many :topics, through: :idea_set
  belongs_to :item_type
  has_many :links, dependent: :destroy, inverse_of: :item
  has_many :reviews, dependent: :destroy, inverse_of: :item
  belongs_to :user # submitter
  validates :name, presence: true, length: { in: 3..250 } # removed uniqeness validation
  validates :item_type, presence: true
  validates :idea_set, presence: true
  validates :user, presence: true
  validates :image_url, allow_blank: true, format: URI::regexp(%w[http https])

  LEVELS = ["childlike","beginner","intermediate","advanced","research"]
  validates :level, inclusion: {in: LEVELS}, allow_nil: true
  before_validation(on: [:create, :update]) do
    self.level = nil if self.level == ''
  end

  validates :links, presence: true, if: -> { item_type_id != 'learning_plan' and !allow_without_links}
  after_save :clear_cache
  after_create :update_points # :notify_gitter
  after_create :notify_slack
  after_destroy :clear_cache
  
  accepts_nested_attributes_for :links, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :idea_set

  attr_accessor :other_item_id
  attr_accessor :allow_without_links

	scope :approved, -> { where(:is_approved => true) }
	scope :unapproved, -> { where(:is_approved => false) }

  scope :curated, -> { where("1 = 1") }
  scope :recent, -> { order("created_at DESC").limit(3) }
  scope :popular, -> { order("(inspirational_score + educational_score + challenging_score + entertaining_score + visual_score + interactive_score) DESC").limit(3) }

  def to_param
    self.id.to_s + "-" + self.name.to_s.parameterize
  end

  def self.from_param(id)
    self.where(id: id.to_s.split("-")[0..4].join("-")).first
  end

  def update_score
  	Review::SCORE_TYPES.each do |quality_score|
  		avg_score = self.reviews.where("#{quality_score} is not null").average(quality_score)
  		self.write_attribute(quality_score, avg_score) if avg_score
    end
    avg_overall_score = self.reviews.with_rating.average(:overall_score)
    self.overall_score = avg_overall_score
    self.save
  end

  def creators
    self.idea_set.person_idea_sets.where(role: 'creator').collect(&:person).collect(&:name).join(", ")
  end

  def authors
    self.idea_set.person_idea_sets.select { |pr| pr.role == 'creator' }.collect(&:person)
  end

  def creators
    self.idea_set.person_idea_sets.select { |pr| pr.role == 'creator' }.collect(&:person)
  end

  def as_json(options = {})
    {
      id: self.id,
      name: self.name.titleize,
      item_type_id: self.item_type_id.titleize,
      creators: self.creators,
      to_param: self.to_param
    }
  end

  def activity_pub_message
    url = Rails.application.routes.url_helpers.item_url(self)

    return "New #{self.item_type_id} added for #{self.topics.map(&:name).join(',')}: <a href='#{url}' target='_blank'>#{self.display_name}</a>"
  end

  def activity_pub(topic)
    {
      "@context": "https://www.w3.org/ns/activitystreams",
      "id": "https://learnawesome.org/post-item-activity-pub/#{self.id}",
      "type": "Create",
      "actor": Rails.application.routes.url_helpers.actor_topic_url(topic),

      "object": {
        "id": Rails.application.routes.url_helpers.item_url(self),
        "type": "Note",
        "published": self.created_at.iso8601,
        "attributedTo": Rails.application.routes.url_helpers.actor_topic_url(topic),
        # "inReplyTo": "https://mastodon.social/@Gargron/100254678717223630",
        "content": self.activity_pub_message,
        "to": "https://www.w3.org/ns/activitystreams#Public"
      }
    }
  end

  def display_item_type
		ItemType.display_name_singular(self.item_type_id)
	end

  def thumbnail
    if self.links.any? { |l| l.url.include?("youtube.com") }
      videoid = Item.youtube_id(self.links.select { |l| l.url.include?("youtube.com") }.first.url)
      return "https://img.youtube.com/vi/#{videoid}/0.jpg"
    else
      return "/icons/#{self.item_type_id}.svg"
    end
  end

  def new_thumbnail
    if self.links.any? { |l| l.url.include?("youtube.com") }
      videoid = Item.youtube_id(self.links.select { |l| l.url.include?("youtube.com") }.first.url)
      return "https://img.youtube.com/vi/#{videoid}/0.jpg"
    elsif self.image_url.present?
      return self.image_url
    else
      "https://source.unsplash.com/640x400/?" + self.topics.first.name.to_s.gsub("/",",").gsub("-",",") + "-" + self.name.to_s.gsub("/",",").gsub("-",",")
    end
  end

  def image_might_be_landscape?
    self.item_type_id == 'video'
  end

  def average_overall_score
    return 0 unless reviews.present?
    scores = reviews.pluck(:overall_score).compact
    return 0 if scores.blank?
    return scores.sum / scores.size
  end

  def get_people(for_user)
    self.reviews.map(&:user).take(5) * 3
  end

  def large_thumbnail
    return self.image_url if self.image_url.present?
    if self.links.any? { |l| l.url.include?("youtube.com") }
      videoid = Item.youtube_id(self.links.select { |l| l.url.include?("youtube.com") }.first.url)
      return "https://img.youtube.com/vi/#{videoid}/0.jpg"
    end
  end

  def self.searchable_language
    'english'
  end

  def is_syllabus?
    self.item_type_id == 'learning_plan' and self.links.blank?
  end

  def can_user_edit?(editor)
    return false if editor.nil? or !editor.is_a?(User)
    return true if Rails.env.development?
    return true if self.is_syllabus? and self.user_id == editor.id
    return false if editor.score < 10_000
    return true
  end

  def can_user_change_related_items?(editor)
    return false if editor.nil? or !editor.is_a?(User)
    return true if Rails.env.development?
    return false if editor.score < 500
    return false if self.is_syllabus?
    return true
  end

  def can_user_add_recommendations?(editor)
    return false if editor.nil? or !editor.is_a?(User)
    return true if Rails.env.development?
    return false if editor.score < 500
    return false if self.is_syllabus?
    return true
  end

  def can_user_destroy?(user)
    return true if user and user.is_core_dev?
    return false
  end

  def self.search(q, max=10, is_fuzzy=true)
  	if q.start_with?('http://') or q.start_with?('https://')
      # canonical URL is now handled in items_controller#search
  		return Link.where(url: q).limit(max).map(&:item)
  	else
      if is_fuzzy
        return Item.where("lower(name) LIKE ?", "%#{q.try(:downcase)}%").limit(max)
      else
        return Item.where(name: q).limit(max)
      end
  	end
  end

  def self.advanced_search(topic_name, item_type, length, quality, second_topic_name = nil, person_kind = nil, published_year = nil, min_score = nil, level = nil, limit = 50)
    results = Item.all

    if topic_name.present?
      topic = Topic.where(name: topic_name).first
      results = results.where(id: topic.items.map(&:id)) if topic

      if second_topic_name.present?
        second_topic = Topic.where(name: second_topic_name).first
        results = results.where(id: second_topic.items.map(&:id)) if second_topic
      end
    end

    if item_type.present?
      results = results.where(item_type_id: item_type)
    end
    
    if length.present?
      range_start = length.split("-").first.to_i
      range_finish = length.split("-").last.to_i
      results = results.where(["case when time_unit = 'minutes' then estimated_time when time_unit = 'hours' then estimated_time * 60 end between :start and :finish", {start: range_start, finish: range_finish}])
    end

    if ['inspirational', 'educational', 'challenging', 'entertaining', 'visual', 'interactive'].include?(quality)
      results = results.where("#{quality}_score >= 4.0")
    end

    if published_year.present?
      results = results.where(year: published_year.to_i..)
    end

    if min_score.present?
      results = results.where(overall_score: min_score.to_f..)
    end

    if person_kind.present?
      results = results.where(idea_set_id: Recommendation.where(person_id: Person.where(kind: person_kind).pluck(:id)).pluck(:idea_set_id))
    end

    if level.present?
      results = results.where(level: level)
    end

    return results.limit(limit)
  end

  def self.discover(topics = nil, item_type_ids = nil)
    items = Item
    items = items.where(item_type_id: item_type_ids) unless item_type_ids.blank?
    items = items.includes(:topics).where('topic_idea_sets.topic_id' => topics.map(&:id)) unless topics.blank?
    found = items.order('RANDOM()').first
    if found.nil?
      return Item.where(item_type_id: item_type_ids).order('RANDOM()').first
    else
      return found
    end
  end

  def self.extract_canonical_url(url)
    # url = 'https://www.goodreads.com/book/show/23692271-sapiens?ac=1&from_search=true'
    begin
      page = Nokogiri::HTML(URI.open(url, :read_timeout => 8))

      return page.at('link[rel="canonical"]')&.attributes["href"]&.value
    rescue Exception => ex
      return nil
    end
  end

  def update_opengraph_data
    extracted = Item.extract_opengraph_data(self.primary_link.url)
    if extracted.present?
      self.image_url = extracted[:image_url] # TODO: don't overwrite existing values
      self.description = extracted[:description] # TODO: same
      self.save
    end
  end

  def self.create_book(book, creator, collection = nil)
    Item.transaction do
      idea_set = IdeaSet.new(name: book.title, description: book.description)
      if book.author_link.present? or book.author_name.present?
        author = Person.where(website: book.author_link).or(Person.where(goodreads: book.author_link)).or(Person.where(name: book.author_name)).first
        if author.nil?
          author = Person.create!(name: book.author_name, website: book.author_link)
        else
          author.update_attributes!(name: book.author_name, website: book.author_link)
        end
        idea_set.person_idea_sets.build(role: 'creator', person_id: author.id)
      end
      idea_set.save!

      book.topics.each do |t|
        idea_set.topic_idea_sets.create!(topic_id: Topic.find_by_name(t).id)
      end

      item = Item.new(name: book.title, item_type_id: 'book', image_url: book.cover_image, user: creator)
      item.idea_set = idea_set

      if book.openlibrary_link.present?
        item.links.build(url: book.openlibrary_link)
      end

      if book.goodreads_link.present?
        item.links.build(url: book.goodreads_link)
      end

      if book.google_books_link.present?
        item.links.build(url: book.google_books_link)
      end

      if book.amazon_link.present?
        item.links.build(url: book.amazon_link)
      end

      if book.direct_link.present?
        item.links.build(url: book.direct_link)
      end

      if item.links.any?
        item.save
        Rails.logger.info("Item created #{item.id}")
        CollectionItem.create(collection: collection, item: item) if collection
      end

      # Now save all related items
      if book.four_minute_books_link.present?
        if (exlink = Link.where(url: book.four_minute_books_link).first).present?
          # Merge the idea_sets
          exlink.item.idea_set = idea_set
          exlink.item.save!
        else
          relitem = Item.new(
            idea_set: idea_set,
            name: book.title + " - Summary by FourMinuteBooks",
            image_url: book.cover_image,
            description: book.description,
            user: creator,
            item_type_id: 'summary')
          relitem.links.build(url: book.four_minute_books_link)
          relitem.save!
        end
      end

      if book.derek_sivers_link.present?
        if (exlink = Link.where(url: book.derek_sivers_link).first).present?
          # Merge the idea_sets
          exlink.item.idea_set = idea_set
          exlink.item.save!
        else
          relitem = Item.new(
            idea_set: idea_set,
            name: book.title + " - Summary by Derek Sivers",
            image_url: book.cover_image,
            description: book.description,
            user: creator,
            item_type_id: 'summary')
          relitem.links.build(url: book.derek_sivers_link)
          relitem.save!
        end
      end

      if book.blas_link.present?
        if (exlink = Link.where(url: book.blas_link).first).present?
          # Merge the idea_sets
          exlink.item.idea_set = idea_set
          exlink.item.save!
        else
          relitem = Item.new(
            idea_set: idea_set,
            name: book.title + " - Summary at Blas.com",
            image_url: book.cover_image,
            description: book.description,
            user: creator,
            item_type_id: 'summary')
          relitem.links.build(url: book.blas_link)
          relitem.save!
        end
      end

    end
  end

  def update_book(book, creator, collection = nil)
    Item.transaction do

      if book.author_link.present? or book.author_name.present?
        author = Person.where(website: book.author_link).or(Person.where(goodreads: book.author_link)).or(Person.where(name: book.author_name)).first
        if author.nil?
          author = Person.create!(name: book.author_name, website: book.author_link)
        else
          author.update_attributes!(name: book.author_name, website: book.author_link)
        end
        idea_set.person_idea_sets.create!(role: 'creator', person_id: author.id)
      end

      if book.goodreads_link.present? && links.where(url: book.goodreads_link).first.nil?
        links.create!(url: book.goodreads_link)
      end

      if book.openlibrary_link.present? && links.where(url: book.openlibrary_link).first.nil?
        links.create!(url: book.openlibrary_link)
      end

      if book.google_books_link.present? && links.where(url: book.google_books_link).first.nil?
        links.create!(url: book.google_books_link)
      end

      if book.amazon_link.present? && links.where(url: book.amazon_link).first.nil?
        links.create!(url: book.amazon_link)
      end

      if book.direct_link.present? && links.where(url: book.direct_link).first.nil?
        links.create!(url: book.direct_link)
      end

      if book.four_minute_books_link.present?
        if related_items.select { |i| i.links.where(url: book.four_minute_books_link).first.present? }.present?
          # pass
        elsif (exlink = Link.where(url: book.four_minute_books_link).first).present?
          # Merge the idea_sets
          exlink.item.idea_set = idea_set
          exlink.item.save!
        else
          relitem = Item.new(
            idea_set: idea_set,
            name: name + " - Summary by FourMinuteBooks",
            user: creator,
            item_type_id: 'summary')
          relitem.links.build(url: book.four_minute_books_link)
          relitem.save!
        end
      end

      if book.derek_sivers_link.present?
        if related_items.select { |i| i.links.where(url: book.derek_sivers_link).first.present? }.present?
          # pass
        elsif (exlink = Link.where(url: book.derek_sivers_link).first).present?
          # Merge the idea_sets
          exlink.item.idea_set = idea_set
          exlink.item.save!
        else
          relitem = Item.new(
            idea_set: idea_set,
            name: name + " - Summary by Derek Sivers",
            user: creator,
            item_type_id: 'summary')
          relitem.links.build(url: book.derek_sivers_link)
          relitem.save!
        end
      end

      if book.blas_link.present?
        if related_items.select { |i| i.links.where(url: book.blas_link).first.present? }.present?
          # pass
        elsif (exlink = Link.where(url: book.blas_link).first).present?
          # Merge the idea_sets
          exlink.item.idea_set = idea_set
          exlink.item.save!
        else
          relitem = Item.new(
            idea_set: idea_set,
            name: name + " - Summary at Blas.com",
            user: creator,
            item_type_id: 'summary')
          relitem.links.build(url: book.blas_link)
          relitem.save!
        end
      end

      self.image_url ||= book.cover_image
      self.description ||= book.description
      self.year ||= book.publish_date
      self.save!
      CollectionItem.create(collection: collection, item: self) if collection
    end
  end

  def self.create_or_update_book(book, creator, collection = nil)
    book.topics.each do |t|
      found = Topic.where(name: t).first
      if found.nil?
        Topic.create!(name: t, search_index: t, gitter_room: t, user: creator)
      end
    end
    link = Link.where(url: [book.amazon_link, book.goodreads_link, book.openlibrary_link, book.direct_link]).first
    if link.present?
      Rails.logger.info "Update 1 #{book.title}"
      link.item.update_book(book, creator, collection)
    elsif (summary_link = Link.where(url: [book.four_minute_books_link, book.derek_sivers_link, book.blas_link]).first).present?
      Rails.logger.info "Update 2 #{book.title}"
      summary_link.item.update_book(book, creator, collection)
    else
      Rails.logger.info "Create 1 #{book.title}"
      Item.create_book(book, creator, collection)
    end
  end

  def self.search_by_isbn(isbn)
    isbn = isbn.gsub(" ","").gsub("-","")
    # ISBN is edition-specific
    Item.where(item_type_id: 'book').where("metadata::text like '%#{isbn}%'").first
  end

  def self.extract_opengraph_data(url)
    # Rails.cache.fetch("grdata_#{url}", expires_in: 12.hours) do
      if url.include?("goodreads.com")
        # url = 'https://www.goodreads.com/book/show/23692271-sapiens?ac=1&from_search=true'
        item_type = 'book'
        page = Nokogiri::HTML(URI.open(url))

        canonical = page.at('link[rel="canonical"]')&.attributes["href"]&.value
        isbn = page.at('meta[property="books:isbn"]')&.attributes["content"]&.value
        #image_url = page.at('meta[property="og:image"]')&.attributes["content"]&.value
        image_url = "http://covers.openlibrary.org/b/isbn/#{isbn}.jpg" if isbn.present?
        title = page.at('meta[property="og:title"]')&.attributes["content"]&.value
        authors = page.search('meta[property="books:author"]').map { |x| x.attributes["content"] }.map(&:value)
        if page.at('meta[property="books:page_count"]')&.attributes
          page_count = page.at('meta[property="books:page_count"]')&.attributes["content"]&.value.to_i
        else
          page_count = nil
        end
        # description = page.at('meta[property="og:description"]')&.attributes["content"]&.value
        description = (page.css("div#description") > "span:last").inner_text
        topics = page.css("a.bookPageGenreLink").map {|n| n.attributes["href"]&.value }.select { |s| s.start_with?("/genres/") }.map { |s|
          Topic.find_by_name(s.gsub("/genres/",""))
        }.compact
        creator_bio = (page.css("div.bookAuthorProfile__about") > "span:last").inner_text

        {
          item_type: item_type,
          canonical: canonical,
          image_url: image_url,
          title: title,
          description: description,
          topics: topics,
          creators: authors,
          creator_bio: creator_bio,
          metadata: {isbn: isbn, page_count: page_count}
        }
      elsif url.include?("youtube.com") or url.include?("vimeo.com")
        opengraph_from_video(url)
      elsif url.include?("wikipedia.org")
        page = Nokogiri::HTML(URI.open(url))
        title = page.at('title')&.content
        canonical = page.at('link[rel="canonical"]')&.attributes["href"]&.value
        {
          item_type: 'wiki',
          topics: [],
          canonical: canonical,
          title: title
        }
      else
        begin
          page = Nokogiri::HTML(URI.open(url))
          title = page.at('title')&.content
          if title.blank? && url.end_with?(".pdf")
            title = File.basename(URI.parse(url).path).sub(".pdf", "").gsub("_", " ").gsub("-", " ")
          end
          canonical = page.at('link[rel="canonical"]')&.attributes && page.at('link[rel="canonical"]')&.attributes["href"]&.value
          {
            topics: [],
            canonical: canonical,
            title: title.to_s.strip
          }
        rescue Exception => ex
          Rails.logger.error "Error: #{ex.message} in extract_opengraph_data"
          {}
        end
      end
    # end
  end

  ##
  # Extract Open Graph data from a video URL.
  #
  def self.opengraph_from_video(url)
    page = Nokogiri::HTML.parse(URI.open(url))
    canonical = page.at('link[rel="canonical"]')&.get_attribute("href")
    image_url = page.at('meta[property="og:image"]')&.get_attribute("content")
    title = page.at('meta[property="og:title"]')&.get_attribute("content")
    description = page.at('meta[property="og:description"]')&.get_attribute("content")

    {
      item_type: 'video',
      topics: [],
      canonical: canonical,
      image_url: image_url,
      title: title,
      description: description
    }
  rescue OpenURI::HTTPError => ex
    Rails.logger.error "Error: #{ex.message} in 'opengraph_from_video'"
    {}
  end

  def read_time
    if self.estimated_time
      self.estimated_time.to_s + " " + self.time_unit
    end
  end

  def detail_params
    list = {}
    list[:published] = self.year if self.year
    list[:language] = self.language if self.language.present?
    list[:cost] = self.cost if self.cost
    list[:time] = self.read_time if self.read_time.present?
    list[:difficulty] = self.level if self.level
    return list
  end

  def display_rating
    Review.display_rating(self.average_overall_score)
  end

  def display_name
    self.name
  end

  def display_description
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: false)
    html = markdown.render(self.description.to_s.strip)
    return html.html_safe #self.replace_la_links_with_embeds(html)
    # simple_format(self.description.to_s.strip)
  end

  def display_protected_description
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: false)
    html = markdown.render(self.protected_description.to_s.strip)
    return html.html_safe #self.replace_la_links_with_embeds(html)
    # simple_format(self.protected_description.to_s.strip)
  end

  def replace_la_links_with_embeds(html)
    # detect all URLs to items in given html string and replace them with their content_html
    pattern = /(https?:\/\/[a-z.]+(:3000)?\/items\/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})(-[a-zA-Z0-9\-_]+)?)/
    html.scan(pattern).each do |match|
      # match = [url, port, itemid, idsuffix]
      html.sub!(match.first, Item.find(match[2]).content_html(match.first))
    end
    html.html_safe
  end

  def content_html(url)
    "<a href=\"" + url + "\" target='_blank'>" + self.display_name + "</a><br/>"
    # + "<iframe src='" + self.embed_url + "' width=600 height=600></iframe><br/>"
    # When items are included in syllabuses, we may want to avoid a few clicks
    # by directly fetching the content of the first/primary link
    # If the item has one link to youtube or soundcloud or image etc, they can directly be shown
    # For some other cases, an <iframe> tag might suffice but that won't always be allowed.
    # This will need a bunch of heuristics and can be improved gradually.
  end

  def combine(other_item)
    return nil if other_item.idea_set_id == self.idea_set_id
    prev_idea_set = other_item.idea_set
    prev_idea_set.items.update(idea_set_id: self.idea_set_id)
    IdeaSet.find(prev_idea_set.id).destroy # destroy after reload
    return nil # success. Return msg in case of failure
  end

  def rss_content
    "<a href='#{self.primary_link.url}'>#{self.primary_link.url}</a>".html_safe +
    self.description.to_s
  end

  def rss_title
    "#{self.item_type_id.to_s}: " + self.name.to_s
  end

  def related_items
    self.idea_set.items.reject { |i| i.id == self.id }
  end

  def clear_cache
    # self.topics.each do |t|
    #   Rails.cache.delete("topic_items_#{t.id}")
    # end
  end

  def notify_gitter
    if Rails.env.production?
      item_url = Rails.application.routes.url_helpers.item_url(self)
      message = "New #{self.item_type} added in #{self.topics.map(&:name).join(',')}: #{self.name}: #{item_url}"
      self.topics.map { |t| t.gitter_room_id.presence || '5ca7a4aed73408ce4fbced18'}.compact.uniq.each do |room_id| # learn-awesome/community
        GitterNotifyJob.perform_later(message,room_id)
      end
    end
  end

  def notify_slack
    if Rails.env.production?
      item_url = Rails.application.routes.url_helpers.item_url(self)
      message = "New #{self.item_type} added in #{self.topics.map(&:name).join(',')}: #{self.name}: #{item_url}"
      self.topics.map { |t| t.slack_room_id.presence || 'new-items'}.compact.uniq.each do |room_id|
        SlackNotifyJob.perform_later(message,room_id)
      end

      # Notify all Slack subscriptions for each of the topics (only once per channel)
      self.topics.map { |t| t.slack_subscriptions }.flatten.uniq { |s| [s.slack_authorization_id, s.channel_id] }.each do |sub|
        SlackSubscriptionNotifyJob.perform_later(message, sub.id)
      end 
    end
  end

  def update_points
    UserPointsService.call(self.user)
  end

  def self.suggest_format(url)
    return "video" if ["youtube.com", "vimeo.com", "youtu.be"].any? { |dom| url.include?(dom) }
    return "wiki" if ["wikipedia.org"].any? { |dom| url.include?(dom) }
    return "book" if ["goodreads.com"].any? { |dom| url.include?(dom) }
    return "course" if ["classcentral.com", "coursera.org", "edx.org"].any? { |dom| url.include?(dom) }
    return "article"
  end

  def embed_url
    if self.links.any? { |l| l.url.include?("youtube.com") or l.url.include?("vimeo.com") or l.url.include?("youtu.be") }
      Item.video_embed(self.links.select { |l| l.url.include?("youtube.com") or l.url.include?("vimeo.com") or l.url.include?("youtu.be") }.first.url)
    elsif self.is_wiki? and self.links.any? { |l| l.url.include?("wikipedia.org") }
      self.links.select { |l| l.url.include?("wikipedia.org") }.first.url.gsub(".wikipedia.org",".m.wikipedia.org")
    elsif self.is_book? and self.links.any? { |l| l.url.include?("archive.org") }
      self.links.select { |l| l.url.include?("archive.org") }.first.url
    elsif self.primary_link && Link::EMBED_ALLOWED_DOMAINS.include?(self.primary_link.top_domain)
      self.primary_link.url
    end
  end

  def book_cover_size_image
    return if self.embed_tag
    return if self.is_video?
    return self.image_url.presence
  end

  def video_thumbnail_size_image
    return unless self.is_video?
    return self.image_url.presence
  end

  def embed_tag
    # self.links.select(&:embed_tag).first
    return unless self.embed_url
    css = ''
    css += 'h-60 md:h-96' if self.is_video?
    html_attr = "height='600'" if ['wiki','book','research_paper'].include?(self.item_type_id)
    return "<iframe allowfullscreen frameborder='0' allow='accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture' class='w-full #{css}' #{html_attr} src='#{self.embed_url}'></iframe>".html_safe
  end

  def is_wiki?
    self.item_type_id == 'wiki'
  end

  def is_book?
    self.item_type_id == 'book'
  end

  def is_video?
    self.item_type_id == 'video'
  end

  def self.youtube_id(youtube_url)
    regex = /(?:youtube(?:-nocookie)?\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})/
    match = regex.match(youtube_url)
    if match && !match[1].blank?
      match[1]
    else
      nil
    end
  end

  def self.video_embed(video_url)

    # REGEX PARA EXTRAER EL ID DEL VIDEO
    regex_id = /(?:youtube(?:-nocookie)?\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/|vimeo\.com\/)([a-zA-Z0-9_-]{8,11})/
    match_id = regex_id.match(video_url)
    video_id = ""
    if match_id && !match_id[1].blank?
      video_id = match_id[1]
    end

    # REGEX PARA EXTRAER EL PROVEEDOR - YOUTUBE/VIMEO
    regex_prov = /(youtube|youtu\.be|vimeo)/
    match_prov = regex_prov.match(video_url)
    video_prov = ""
    if match_prov && !match_prov[1].blank?
      video_prov = case match_prov[1]
                     when "youtube"
                       :youtube
                     when "youtu.be"
                       :youtube
                     when "vimeo"
                       :vimeo
      end
    end

    return nil unless video_id.present? && video_prov.present?

    case video_prov
      when :youtube
        "https://www.youtube.com/embed/#{video_id}"
      when :vimeo
        "https://player.vimeo.com/video/#{video_id}"
    end
  end

  def recommended_items(user)
    [Item.discover]    
  end

  def primary_link
    @primary_link ||= (self.links.find { |l| l.is_primary } or self.links.sort_by(&:created_at).first)
  end

  def alternative_links
    self.links.reject { |l| l.id == self.primary_link.id }
  end

  def display_format
    ItemType.display_name_singular(self.item_type_id)
  end

  def og_description
    msg = "a #{self.display_format} about #{self.topics.map(&:display_name).to_sentence}"
    return msg[0..400]
  end

  def og_keywords
    (["learning",self.display_format] + self.topics.map(&:display_name)).join(',')
  end

  def og_image
      self.new_thumbnail.presence || 'https://learnawesome.org/stream/assets/img/ogimage.png'
  end

  def og_title
    "#{self.display_name} :: LearnAwesome.org"
  end
end

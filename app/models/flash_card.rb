# == Schema Information
#
# Table name: flash_cards
#
#  id                   :uuid             not null, primary key
#  question             :text             not null
#  answer               :text             not null
#  level                :integer          default(1), not null
#  url                  :string
#  last_practiced_at    :datetime
#  practice_count       :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  next_practice_due_at :datetime         not null
#  user_id              :uuid             not null
#  deck_id              :uuid             not null
#
class FlashCard < ApplicationRecord
    validates :question, length: { in: 1..2000 }
    validates :answer, length: { in: 1..2000 }
    validates :level, inclusion: { in: 1..11 }
    validates :user, presence: true
    # TODO: validate that flashcard owner is same as its deck's owner

    scope :of_user, ->(user_id) { where(user_id: user_id) }
    scope :least_practiced, -> { order(:next_practice_due_at, :practice_count, :last_practiced_at, :level) }
    scope :past_due_for_practice, -> { where("next_practice_due_at <= ?", Time.current) }

    belongs_to :user
    belongs_to :deck

    attr_accessor :skip_inverted_card
    after_save :create_inverted_card, unless: :skip_inverted_card

    def create_inverted_card
        FlashCard.create(
            user: self.user, 
            level: 1, 
            question: self.answer, 
            answer: self.question,
            skip_inverted_card: true
        )
    end

    def self.bulk_create_by_notes(user, subject, body)
        # Split the text into sentences, pick the answer from string within brackets {},
        # turn the rest of the sentence into a question with placeholder ____ and save as flashcard
        # TODO: use subject to create a deck object
        body.split("\n").reject(&:blank?).map do |sentence|
            answer = sentence.scan(/{[^}]+}/).first
            return [] if answer.nil?
            question = sentence.gsub(answer, " ___ ")
            answer = answer.gsub("{","").gsub("}","")
            [question, answer]
        end.each do |pair|
            next if pair.blank?
            FlashCard.create(user: user, question: pair.first, answer: pair.last, level: 1)
        end
    end

    def did_recall
        self.level += 1
        self.last_practiced_at = Time.now
        self.set_next_practice_due_at_on_successful_recall
        self.save!
        FlashCard.card_to_practice_next(self.user)
    end

    def did_not_recall
        self.level = 1
        self.last_practiced_at = Time.now
        self.set_next_practice_due_at_on_failed_recall
        self.save!
        FlashCard.card_to_practice_next(self.user)
    end

    private

    # When a flash card is recalled successfully, its level gets elevated.
    # Thus, we also double the # of days required until its next practice due.
    #
    # For an example, if the 'level' is elevated
    #   - to 2 then 'next_practice_due_at' is set to 2 days from now
    #   - to 3 then 'next_practice_due_at' is set to 4 days from now
    #   - to 4 then 'next_practice_due_at' is set to 8 days from now
    #   - to 5 then 'next_practice_due_at' is set to 16 days from now
    #   - to 6 then 'next_practice_due_at' is set to 32 days from now
    #   - and so on...
    def set_next_practice_due_at_on_successful_recall
        self.next_practice_due_at = Time.current + ( 2 ** (self.level - 1)).days
    end

    # When a flash card is NOT recalled successfully, its level gets reset.
    # Thus, we set its next practice due to 1 second past from now
    # so that it can be practiced again.
    def set_next_practice_due_at_on_failed_recall
        self.next_practice_due_at = Time.current - 1.second
    end

    # Note that this method can return a nil response which means there are
    # no eligible flash cards available to practice at this moment.
    def self.card_to_practice_next(user, deck=nil)
        FlashCardPracticeService.new(user, deck).card_to_practice_next
    end
end

# == Schema Information
#
# Table name: decks
#
#  id          :uuid             not null, primary key
#  name        :string
#  user_id     :uuid             not null
#  is_public   :boolean          default(FALSE), not null
#  description :string
#  image_url   :string
#  tags        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Deck < ApplicationRecord
  validates :name, length: {in: 4..80}
  validates :user, presence: true

  scope :of_user, ->(user_id) { where(user_id: user_id) }
  belongs_to :user
  has_many :flash_cards, dependent: :destroy

  def image
    self.image_url || "https://picsum.photos/seed/#{self.id}/200/100"
  end

end

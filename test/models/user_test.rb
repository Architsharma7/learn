# == Schema Information
#
# Table name: users
#
#  id                         :uuid             not null, primary key
#  nickname                   :string           not null
#  image_url                  :string
#  bio                        :string
#  description                :text
#  score                      :integer          default(100), not null
#  role                       :string           default("regular"), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  random_fav_topic           :boolean          default(FALSE), not null
#  random_fav_item_types      :string
#  referrer                   :string
#  unsubscribe                :boolean          default(FALSE), not null
#  has_used_browser_extension :boolean          default(FALSE), not null
#  has_used_embed             :boolean          default(FALSE), not null
#  tiddlywiki_url             :string
#  theme                      :string
#  rocketchat_logintoken      :string
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

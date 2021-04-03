# == Schema Information
#
# Table name: people
#
#  id            :uuid             not null, primary key
#  name          :string           not null
#  description   :text
#  website       :string
#  email         :string
#  twitter       :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  metadata      :json             not null
#  goodreads     :string
#  image_url     :string
#  kind          :string
#  second_kind   :string
#  wikipedia_url :string
#  youtube_url   :string
#

require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

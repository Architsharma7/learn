# == Schema Information
#
# Table name: links
#
#  id            :uuid             not null, primary key
#  url           :string           not null
#  item_id       :uuid             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  name          :string
#  is_primary    :boolean
#  embed_tag     :string
#  mimetype      :string
#  has_paywall   :boolean
#  has_loginwall :boolean
#  has_ads       :boolean
#

require 'test_helper'

class LinkTest < ActiveSupport::TestCase
	test "topdomain" do
		assert_equal links(:google_link).top_domain, "google.com"
	end
end

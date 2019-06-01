class ItemsController < ApplicationController
  # include Secured
  def index
  end

  def show
  	@item = Item.find(params[:id])
  end

  def new
  end

  def create
    item = nil
    Item.transaction do
      idea_set = IdeaSet.new
      idea_set.name = params[:item][:name]
      idea_set.save

      params[:item][:topic].each do |topic_id|
        TopicIdeaSet.create(topic_id: topic_id, idea_set: idea_set)
      end

      item = Item.new(params.require(:item).permit(:name, :item_type_id))
      item.idea_set = idea_set
      item.links.build
      item.links.first.url = params[:item][:url]

      unless item.save
        raise item.errors.first.inspect
      end
    end
    if item
  	  redirect_to item
    else
      redirect_to :back
    end
  end

  def search
  	@q = params[:q]
  	if @q.present?
  		items = Item.search(@q)
  		if items.first
  			redirect_to items.first
  		elsif @current_user
        if is_url?(@q)
          redirect_to new_item_path(url: @q)
        else
          redirect_to new_item_path(name: @q)
        end
      else
        # render search
      end
  	end
    # render search form
  end

  def discover
    redirect_to Item.discover
  end

  private
  def is_url?(q)
    q.start_with?('http://') or q.start_with?('https://')
  end
end

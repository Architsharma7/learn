require 'openai'

class TopicsController < InheritedResources::Base
  include Secured
  before_action :logged_in_using_omniauth?, only: [:toggle_follow, :new, :create, :merge, :edit, :update, :wiki_update, :destroy]
  before_action :permission_check, only: [:merge, :edit, :update, :wiki_update, :destroy]
  skip_before_action :verify_authenticity_token, :only => [:inbox]
  
  respond_to :html, :json
  actions :all

  # def index
  #     respond_to do |format|
  #       format.html
  #       format.json { render json: Topic.all }
  #     end
  # end

  # def new
  #   @topic = Topic.new
  #   @topic.name = params[:name]
  # end

  # def create
  #   @topic = Topic.new
  #   @topic.display_name = params[:topic][:name].to_s.strip
  #   @topic.name = @topic.display_name.gsub(" ", "-").downcase
  #   @topic.search_index = @topic.name
  #   @topic.gitter_room = @topic.name
  #   @topic.user = current_user
  #   if @topic.save
  #     redirect_to @topic
  #   else
  #     flash[:danger] = @topic.errors.first
  #     render :new
  #   end
  # end

  def show
    @item_type = params[:item_type]
    @length = params[:length]
    @quality = params[:quality]
    @level = params[:level].presence # which tab to show selected by default
    @topic = Topic.from_param(params[:id])
    if @topic.nil?
        flash[:danger] = "We couldn't find this topic."
        redirect_to root_path and return
    end
    if current_user
      @user_topics = current_user.user_topics
      @does_follow = @user_topics.find { |ut| (ut.topic_id == @topic.id) && (ut.action == 'follow') }
    end

    @item_type_items = @topic.advanced_search(@item_type, @length, @quality, @level)

    @learning_plans = @topic.advanced_search('learning_plan', nil, nil)
  end

  def graph
      respond_to do |format|
        format.html
        format.json
      end
  end

  def explore
    @topic = Topic.from_param(params[:id])
  end

  def toggle_follow
    @topic = Topic.from_param(params[:id])
    if current_user
      @user_topics = current_user.user_topics
      @topic_action = @user_topics.find { |ut| ut.topic_id == @topic.id }
      if @topic_action
        @topic_action.destroy
      else
        @user_topics.create!(topic: @topic, action: "follow")
      end
      # Rails.cache.delete("user_onboarding_#{current_user.id}")
    end
    redirect_to @topic
  end

  def search
    fuzzy_results = Topic.fuzzy_search(params[:q]).limit(10)
    results = fuzzy_results.empty? ? Topic.search(params[:q]) : fuzzy_results
    render :json => results.as_json(only: [:id, :name])
  end

  def discover
      topic = Topic.discover
      if topic
        redirect_to topic
      else
        flash[:danger] = "No topics exist."
        redirect_to root_path
      end
  end

  def merge
    if request.post?
      Topic.merge(Topic.from_param(params[:id]).id, params[:duplicate_id])
      flash[:success] = "Topics merged successfully."
      redirect_to merge_topic_path(id: params[:id]) and return
    else
      @topic = Topic.from_param(params[:id])
      @topics = Topic.where.not(id: @topic.id).order(:name)
    end
  end

  def wiki_update
    @topic = Topic.from_param(params[:id])
    if @topic.update_from_wiki
      flash[:success] = "Topic data updated from Wikipedia"
    end
    redirect_to @topic
  end

  def destroy
    @topic = Topic.from_param(params[:id])
    if @topic.do_delete!
      flash[:success] = "Topic has been deleted"
    end
    redirect_to topics_path
  end

  def custom
    @topic = Topic.from_param(params[:id])
    if request.get?
      @form = CustomTopicForm.new
    else
      @form = CustomTopicForm.new(params: params[:custom_topic_form])

      if @form.process
        redirect_to @topic, notice: "Changes have been saved! #{@form.age} #{@form.email}"
      else
        render
      end
    end
  end

  def practice
    @topic = Topic.from_param(params[:id])
    unless @topic.is_gpt_enabled?(current_user)
      flash[:danger] = "GPT-3 is not enabled"
      redirect_to @topic and return
    end
    if request.get?
      @questions = @topic.gpt_questions(current_user)
    elsif request.post?
      # check answers
      qna = [
        [params["question_0"], params["answer_0"]],
        [params["question_1"], params["answer_1"]],
        [params["question_2"], params["answer_2"]],
        [params["question_3"], params["answer_3"]],
        [params["question_4"], params["answer_4"]],
        [params["question_5"], params["answer_5"]],
        [params["question_6"], params["answer_6"]]
    ].reject { |qa| qa.compact.empty? }
      @qna = @topic.gpt_check_answers(qna)
      render 'evaluate'
    end
  end

  def actor
    @topic = Topic.from_param(params[:id])
    render json: @topic.actor_json
  end

  def ap_followers
    @topic = Topic.find(params[:id])
    render json: @topic.ap_followers_json(request, params)
  end

  def ap_following
    @topic = Topic.find(params[:id])
    render json: @topic.ap_following_json(request, params)
  end

  def inbox
    @topic = Topic.from_param(params[:id])
    headers = request.headers.env.reject { |key| key.to_s.include?('.') }
    post_body = request.raw_post
    Rails.logger.info "headers = #{headers.inspect}"
    Rails.logger.info "body = #{post_body}"
    result, message = @topic.add_to_inbox!(headers, post_body)
    unless result
      raise message
    end
    render json: {message: message}, status: (result ? 200 : 400)
  end

  def outbox
    @topic = Topic.from_param(params[:id])
    render json: @topic.outbox_json(request, params)
  end

  protected
  def resource
    @topic = Topic.from_param(params[:id])
  end

  private

  def permission_check
   handlers = {edit: :can_edit_topic?, update: :can_edit_topic?, destroy: :can_delete_topic?, merge: :can_merge_topic?, wiki_update: :can_wiki_update_topic?}
    if !current_user.try(handlers[params[:action].to_sym])
      flash[:danger] = "Not allowed"
      redirect_to topic_path(id: params[:id]) and return
    end
  end

  def topic_params
    params.require(:topic).permit(:display_name, :name, :search_index, :gitter_room,
    :gitter_room_id, :slack_room_id, :parent_id, :second_parent_id, :description, :image_url, :gpt_quiz_prompt, :gpt_answer_prompt)
  end
end

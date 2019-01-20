# name: votecount
# about: Plugin for Discourse to show votecount for Mafia games (for Mafia451)
# version: 0.0.1
# authors: KC Maddever (kcereru)
# url: https://github.com/kcereru/votecount

VOTECOUNT_PLUGIN_NAME ||= "votecount".freeze

enabled_site_setting :votecount_enabled

after_initialize do
  module ::Votecount
    class Engine < ::Rails::Engine
      engine_name VOTECOUNT_PLUGIN_NAME
      isolate_namespace Votecount
    end
  end

  ::Votecount::Engine.routes.draw do
    get   "/:topic_id/:post_number" => "votecount#get_latest"
  end

  Discourse::Application.routes.append do
    mount ::Votecount::Engine, at: "/votecount"
  end

  class ::Votecount::VotecountController < ApplicationController

    def get_latest
        # post.raw will access the raw of the post
        render json: [ { 'voter': 'Ellibereth', 'votee': 'fferyllt'}, { 'voter': 'Keychain', 'votee': 'Elli'}, {'voter': 'Chesskid', 'votee': 'Elli'} ]
    end

    private

    def post
      @post ||= Post.find_by("topic_id = :topic_id AND post_number = :post_number", topic_id: params[:topic_id], post_number: params[:post_number]) if params[:topic_id] && params[:post_number]
    end

    def verify_post
      respond_with_unprocessable("Unable to find post") unless post
    end

    def respond_with_unprocessable(error)
      render json: { errors: error }, status: :unprocessable_entity
    end

    def get_votes
        # get the votes from the previous post
        # add any votes from the current post
    end
  end
end
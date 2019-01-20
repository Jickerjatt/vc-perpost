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
    post   "/:post_id" => "votecount#get_latest"
  end

  Discourse::Application.routes.append do
    mount ::Votecount::Engine, at: "/votecount"
  end

  class ::Votecount::VotecountController < ApplicationController

    def get_latest
        render json: { 'Votee': ['Voter1', 'Voter2', 'Voter3'] }
    end

    private

    def post
      @post ||= Post.find_by(id: params[:post_id]) if params[:post_id]
    end

    def verify_post
      respond_with_unprocessable("Unable to find post #{params[:post_id]}") unless post
    end

    def respond_with_unprocessable(error)
      render json: { errors: error }, status: :unprocessable_entity
    end
  end
end
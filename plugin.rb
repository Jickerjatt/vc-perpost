# name: votecount
# about: Plugin for Discourse to show votecount for Mafia games (for Mafia451)
# version: 0.0.1
# authors: KC Maddever (kcereru)
# url: https://github.com/kcereru/votecount

VOTECOUNT_PLUGIN_NAME ||= "votecount".freeze
NO_VOTE = 'no one'

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
        render json: get_votes(params[:post_number].to_i)
    end

    private

    def post
      @post ||= Post.find_by("topic_id = :topic_id AND post_number = :post_number", topic_id: params[:topic_id], post_number: params[:post_number]) if params[:topic_id] && params[:post_number]
    end

    def specific_post(p_number)
      Post.find_by("topic_id = :topic_id AND post_number = :post_number", topic_id: params[:topic_id], post_number: p_number) if params[:topic_id] && params[:post_number]
    end

    def verify_post
      respond_with_unprocessable("Unable to find post") unless post
    end

    def respond_with_unprocessable(error)
      render json: { errors: error }, status: :unprocessable_entity
    end

    def get_votes(p_number)

      # if no previous post, return

      if(p_number == 1)
        return []
      end


      # regex post and get tags

      m = /\[vote\](?<vote>.+)\[\/vote\]|\[v\](?<vote>.+)\[\/v\]|(?<unvote>\[unvote\]).*\[\/unvote\]|(?<reset>\[reset\]).*\[\/reset\]/i.match(specific_post(p_number).raw)
      v = Hash[]
      if(m)
        v = m.named_captures
      end


      # if reset, return

      if(v["reset"])
        return []
      end


      # get entry - if there's a vote use that, otherwise use unvote

      vote_value = nil
      if(v["vote"])
        vote_value = v["vote"]
      elsif(v["unvote"])
        vote_value = NO_VOTE
      end



      # get author of current post and votes from prev post and check they're in the array

      author          = specific_post(p_number).username;
      last_post_votes = get_votes(p_number-1)


      # check if post author already has a vote registered - if not then add them

      present = false
      last_post_votes.each  do | item |

        if(item["voter"] == author)

          present = true
          if(vote_value)
            item["votee"] = vote_value
            break

          end

        end

      end

      if(!present)
        if(vote_value)
          last_post_votes.push(Hash["voter" => author, "votee" => vote_value])
        else
          last_post_votes.push(Hash["voter" => author, "votee" => NO_VOTE])
        end
      end

      return last_post_votes

    end
  end
end
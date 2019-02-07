# name: votecount
# about: Plugin for Discourse to show votecount for Mafia games (for Mafia451)
# version: 0.1
# authors: KC Maddever (kcereru)
# url: https://github.com/kcereru/votecount

require 'rubygems'
require 'nokogiri'

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


      # get last post votes

      last_post_votes = get_votes(p_number-1)


      # remove blockquotes

      if(! specific_post(p_number))
        return last_post_votes
      end

      html  = specific_post(p_number).cooked
      doc   = Nokogiri::HTML.parse(html)

      doc.search('blockquote').remove

      elements = doc.xpath("//span[@class='vote']")


      # split array of elements into hash of tag: value

      v = Hash[elements.collect { |element| element.text.split(" ", 2) } ]


      # if reset, return

      if(v.has_key? 'RESET')
        return []
      end


      # if author is OP, return last post votes

      author          = specific_post(p_number).username
      op              = specific_post(1).username


      if(author == op)
        return last_post_votes
      end


      # get entry - if there's a vote use that, otherwise use unvote

      vote_value = nil
      if(v["VOTE:"])
        vote_value = v["VOTE:"]
      elsif(v["UNVOTE:"])
        vote_value = NO_VOTE
      end


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
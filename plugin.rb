# name: votecount
# about: Plugin for Discourse to show votecount for Mafia games (for Mafia451)
# version: 1.0.2
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


      # remove blockquotes and get all vote/votecount class elements

      if(specific_post(p_number))

        html  = specific_post(p_number).cooked
        doc   = Nokogiri::HTML.parse(html)

        doc.search('blockquote').remove

        vote_elements   = doc.xpath("//span[@class='vote']")
        vc_elements     = doc.xpath("//div[@class='votecount']")


        # if reset, return

        author          = specific_post(p_number).username
        op              = specific_post(1).username

        if(vote_elements.any? { |element| element.text == 'RESET' } && author == op)
          return []
        end


        # posts should only contain one votecount - but we'll take the last just in case
        # if there is a vc tag made by the author use that to set votes

        if(vc_elements.last && author == op)
          stripped = ActionController::Base.helpers.strip_tags(vc_elements.last.text)
          vote_lines = stripped.split("\n")
          votes = []
          vote_lines.each do |line|
            # get line data

            # remove parentheses containing totals
            line.gsub!(/\(.*\)/, "")
            votee, players = line.split(":", 2)
            unless players.to_s.strip.empty?
              if(votee.strip.downcase.eql? "not voting")
                votee = NO_VOTE
              end
              players.split(",").each do |voter|
                # create entry in return array
                votes.push(Hash["voter" => voter.strip, "votee" => votee.strip])
              end
            end
          end
          return votes
        end


        # if author is OP, return last post votes

        last_post_votes = get_votes(p_number-1) # recursive call


        if(author == op)
          return last_post_votes
        end


        # get last entry in array

        if(vote_elements.last)
          vote_type, vote_value = vote_elements.last.text.split(" ", 2)
          if(vote_type == "UNVOTE")
            vote_value = NO_VOTE
          else
            vote_value = ActionController::Base.helpers.strip_tags(vote_value)
          end
        end


        # check if post author already has a vote registered - if not then add them
        # maintain order by removing existing entry if they already have one

        present = false
        last_post_votes.each  do | item |

          if(item["voter"] == author)

            # author is already in the list
            present = true

            if(vote_value) # author has made a new action

              # delete old action and replace with new one

              last_post_votes.delete(item)
              last_post_votes.push(Hash["voter" => author, "votee" => vote_value, "post" => p_number])

              break

            end

          end

        end

        if(! present)
          if(vote_value) # author has made an action
            last_post_votes.push(Hash["voter" => author, "votee" => vote_value, "post" => p_number])
          else # author has not made an action
            last_post_votes.push(Hash["voter" => author, "votee" => NO_VOTE])
          end
        end

        return last_post_votes

      else
        return get_votes(p_number-1)
      end

    end
  end
end

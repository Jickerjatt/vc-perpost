# name: votecount
# about: Plugin for Discourse to show votecount for Mafia games (for Mafia451)
# version: 1.3.0
# authors: KC Maddever (kcereru)
# url: https://github.com/kcereru/votecount

require 'rubygems'
require 'nokogiri'

VOTECOUNT_PLUGIN_NAME ||= "votecount".freeze
NO_VOTE = 'NO_VOTE'

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
      render json: Hash["votecount" => get_votes(params[:post_number].to_i), "alive" => get_living(params[:post_number].to_i)]
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

    def get_living(p_number)


      html  = specific_post(p_number).cooked
      doc   = Nokogiri::HTML.parse(html)

      alive_elements  = doc.xpath("//div[@class='alive']")

      if(!alive_elements.last)
        if(p_number == 1)
          return []
        else
          return get_living(p_number-1) # recursive call
        end
      end

      stripped        = ActionController::Base.helpers.strip_tags(alive_elements.last.text)
      players         = stripped.split("\n")


      # remove @

      players.map! {|player| player.tr('@', '')}


      # don't return empty lines

      return players.reject(&:blank?)

    end

    def get_default_votes(p_number)
      votes = []
      alive = get_living(p_number)
      alive.each do |voter|
        votes.push({ 'voter' => voter, 'votes' => [ NO_VOTE ]})
      end
      return votes
    end

    def get_votes(p_number)

      # if no previous post, return

      if(p_number == 1)
        return get_default_votes(p_number)
      end

      # if post is not made by a player or the host, ignore

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
        alive           = get_living(p_number)

        if(vote_elements.any? { |element| element.text == 'RESET' } && author == op)
          return get_default_votes(p_number)
        end


        # posts should only contain one votecount - but we'll take the last just in case
        # if there is a vc tag made by the author use that to set votes

        if(vc_elements.last && author == op)
          stripped = ActionController::Base.helpers.strip_tags(vc_elements.last.text)
          vote_lines = stripped.split("\n")
          voters = Hash.new
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
                # add this vote to each voter
                if voters.include?(voter)
                  voters[voter].push(votee.strip)
                else
                  voters[voter] = [votee.strip]
                end
              end
            end
          end
          votes = []
          voters.each do | voter, votees |
            votes.push({ 'voter' => voter, 'votes' => votees })
          end
          return votes
        end


        # if author is not a player, return last post votes

        last_post_votes = get_votes(p_number-1) # recursive call
        return last_post_votes if (!alive.include?(author))


        # get all the votes in the post

        vote_values = []
        vote_elements.each do |vote_element|
          vote_type, vote_value = vote_element.text.split(" ", 2)
          if(vote_type == "UNVOTE")
            # if there is an unvote, only the unvote is kept
            vote_values = [NO_VOTE]
            break
          else
            vote_value = ActionController::Base.helpers.strip_tags(vote_value)
            vote_value.gsub!('@', '') if vote_value
            vote_values << vote_value
          end
        end


        # check if post author already has a vote registered - if not then add them
        # maintain order by removing existing entry if they already have one

        present = false
        last_post_votes.each  do | item |

          if(item["voter"] == author)

            # author is already in the list
            present = true

            if(vote_values.length > 0) # author has made a new action

              # delete old action and replace with new one

              last_post_votes.delete(item)
              last_post_votes.push({"voter" => author, "votes" => vote_values, "post" => p_number})

              break

            end

          end

        end

        if(! present)
          if(vote_values.length > 0) # author has made an action
            last_post_votes.push({"voter" => author, "votes" => vote_values, "post" => p_number})
          else # author has not made an action
            last_post_votes.push({"voter" => author, "votes" => [NO_VOTE]})
          end
        end

        return last_post_votes

      else
        return get_votes(p_number-1)
      end

    end
  end
end

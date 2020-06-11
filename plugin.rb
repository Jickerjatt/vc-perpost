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
      # check if post exists - if no, return the previous post's living

      this_post = specific_post(p_number)
      return get_living(p_number-1) if this_post.nil?

      # post exists
      # check if post author is the op - if no, return the previous post's living

      author  = this_post.username
      op      = specific_post(1).username

      return get_living(p_number-1) if author != op

      # this post is by the host so could include a list of living players, parse html

      doc   = Nokogiri::HTML.parse(this_post.cooked)
      doc.search('blockquote').remove

      # check if post contains alive tags - if so, return the living from those

      alive_elements  = doc.xpath("//div[@class='alive']")

      return get_players_from_alive_tags(alive_elements) if alive_elements.last

      # check if post contains votecount tags - if so, return living from those

      votecount_elements = doc.xpath("//div[@class='votecount']")

      return get_players_from_votecount_tags(votecount_elements) if votecount_elements.last

      # if it has neither of those tags, return living from the previous post

      return get_living(p_number-1)
    end

    # this assumes alive_elements contains at least one item
    def get_players_from_alive_tags(alive_elements)
      stripped        = ActionController::Base.helpers.strip_tags(alive_elements.last.text)
      players         = stripped.split("\n")

      # remove @

      players.map! {|player| player.tr('@', '')}

      # don't return empty lines

      return players.reject(&:blank?)
    end

    # this assumes votecount_elements contains at least one item
    def get_players_from_votecount_tags(votecount_elements)
      voters = get_players_with_votes_from_votecount_tags(votecount_elements)
      return voters.keys
    end

    # this assumes votecount_elements contains at least one item
    def get_players_with_votes_from_votecount_tags(votecount_elements)
      stripped  = ActionController::Base.helpers.strip_tags(votecount_elements.last.text)
      lines     = stripped.split("\n")
      voters    = Hash.new

      lines.each do |line|

        # remove parentheses containing totals

        line.gsub!(/\(.*\)/, "")
        votee, players = line.split(":", 2)

        # only look at lines with content

        unless players.to_s.strip.empty?

          # not voting is a special case, set the votee

          if(votee.strip.downcase.eql? "not voting")
            votee = NO_VOTE
          end

          # split the voters and add the votee to each of them

          players.split(",").each do |voter|

            # check if the voter exists first

            if voters.include?(voter)
              voters[voter].push(votee.strip)
            else
              voters[voter] = [votee.strip]
            end # end check for voter existence
          end # end iteration through voters on one line
        end # end check for empty line
      end # end iteration through lines
      return voters
    end

    def get_votes_from_votecount_tags(votecount_elements)
      voters = get_players_with_votes_from_votecount_tags(votecount_elements)

      # change voter => [votes] hash to array of {'voter'=>voter, 'votes'=>votes} hashes

      votes = []
      voters.each do | voter, votees |
        votes.push({ 'voter' => voter, 'votes' => votees })
      end

      return votes
    end

    def get_all_votes_from_vote_tags(vote_elements)

        # get all the votes in the post

        votes = []
        vote_elements.each do |vote_element|
          vote_type, vote_value = vote_element.text.split(" ", 2)
          if(vote_type == "UNVOTE")
            # if there is an unvote, only the unvote is kept
            votes = [NO_VOTE]
            break
          else
            vote_value = ActionController::Base.helpers.strip_tags(vote_value)
            vote_value.gsub!('@', '') if vote_value
            votes << vote_value
          end
        end

        return votes
    end

    def get_updated_votes(votecount, p_number, votes)
      # check if player already has a vote registered - if not then add them
      # maintain order by removing existing entry if they already have one

      player = specific_post(p_number).username

      present = false
      votecount.each  do | item |

        if(item["voter"] == player)

          # player is already in the list
          present = true

          if(votes.length > 0) # player has made a new action

            # delete old action and replace with new one

            votecount.delete(item)
            votecount.push({"voter" => player, "votes" => votes, "post" => p_number})

            break
          end
        end
      end

      if(! present)
        if(votes.length > 0) # player has made an action
          votecount.push({"voter" => player, "votes" => votes, "post" => p_number})
        else # player has not made an action
          votecount.push({"voter" => player, "votes" => [NO_VOTE]})
        end
      end

      return votecount
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
      # check if p_number is the first post (or earlier if something's up) - if so, return default votes for the first post

      return get_default_votes(1) if p_number <= 1

      # post number is greater than 1
      # check if post exists - if no, return the previous post's votes

      this_post = specific_post(p_number)
      return get_votes(p_number-1) if this_post.nil?

      # post exists
      # check if post author is a relevant person (living player or host) - if no, return previous post's votes

      author  = this_post.username
      op      = specific_post(1).username
      players = get_living(p_number)

      return get_votes(p_number-1) unless op == author or players.include?(author)

      # this post is by a relevant person, parse html

      doc   = Nokogiri::HTML.parse(this_post.cooked)
      doc.search('blockquote').remove

      # check if it's the host - if so, check for votecount elements

      if(op == author)

        # check for reset tags - if present, return default votes

        vote_elements   = doc.xpath("//span[@class='vote']")

        if(vote_elements.any? { |element| element.text == 'RESET' })
          return get_default_votes(p_number)
        end

        # check for votecount tags - if present, return votes from there

        votecount_elements = doc.xpath("//div[@class='votecount']")

        return get_votes_from_votecount_tags(votecount_elements) if votecount_elements.last

        # if neither of those returned, return previous post's votes

        return get_votes(p_number-1)

      else

        # author is a player, check for votes and add to previous post's votes, return that

        vote_elements   = doc.xpath("//span[@class='vote']")
        last_post_votes = get_votes(p_number-1)

        votes = get_all_votes_from_vote_tags(vote_elements) if vote_elements.last
        return get_updated_votes(last_post_votes, p_number, votes)
      end
    end
  end
end

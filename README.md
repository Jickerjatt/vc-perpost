# Votecount Per Post

A Discourse plugin for playing forum mafia, which provides the votecount as of each post as a button on the post. This removes pressure on the host to constantly be tracking votes and posting votecounts, and makes it far more convenient for players to always know where the votes are at.

Developed for [Mafia451](https://forum.mafia451.com/c/mafiagames/8) - open a game topic and click the gavel icon on a post to see it in action.


## Usage

### Starting a game

If you want the votecounter to track votes in a topic, you'll need to use `[alive]` tags to describe all the players who can vote/be voted for in your game. This is a host-exclusive tag, meaning it will only be processed if made by the user who created the topic.

```
[alive]
@Player1
@Player2
@Player3
[/alive]
```

@ mention all your players between these tags. Make sure you've got the case and spelling right, and don't add anything to their names - the votecounter will only count votes from the players in those tags, so the usernames have to match exactly. It’s easiest to do this by using the @ drop down’s auto-completion.

After players have died (daykill, vote out + nightkills) and you’re ready to start a new day/game phase, list the remaining living players between alive tags as you ping them, and this will make sure the votecounter doesn't include dead players. 

### Voting

Only players listed as alive will be able to vote (that is, have their vote reflected in the count). Vote for a player with `[vote]Player[/vote]`, and unvote completely with `[unvote][/unvote]`. Don't specify a player when unvoting, leave the tags empty.

The votecounter will try to match a vote to an alive player. This is what it will do:
- Case is ignored, so `[vote]pLAYer[/vote]` will be correctly attributed to a player in the alive list with the username `Player`.
- Spaces are ignored, so `[vote]Play er[/vote]` will be correctly attributed to a player in the alive list with the username `Player`.
- Substrings are accepted, so `[vote]Play[/vote]` will be correctly attributed to a player in the alive list with the username `Player`, ASSUMING they are the only one who it's a substring for. If you've also got `PlayBall` in the list, the vote is ambiguous. It'll be assigned to one of the two, so it's up to the host to decide what to do with the ambiguity.

Two scenarios that might come up are players using acronyms or making typos in votes. In that case, the quickest solution is to edit the post the vote was made in to correct all votecounts coming after it. Other options are for the player to make another, correct vote, or for the host to post a manual votecount with the vote corrected (see Manual Votecounts below).

### Viewing the votecount

The votecount as of a post can be viewed in a modal by selecting the gavel icon on that post. It will show a "Classic Votecount" in this format:
```
Player3 (2): Player1, Player2

Not Voting (1): Player3
```

Selecting "Show Player Votes" will show each player's vote exactly as they made it. If it was made since the host posted the last manual votecount, it will also show the post the vote was made in.

### Manual votecounts

The host can copy the contents of the votecount modal to post it as its own post. Enclosing it in `[votecount]` tags mean that the votecounter will parse it and accept that as the votecount as at that post. This is a host-exclusive tag, meaning it will only be processed if made by the user who created the topic. For example:

```
[votecount]
Player3 (2): Player1, Player2

Not Voting (1): Player3
[/votecount]
```

There's a few reasons a host might want to do this. 

First is making corrections. If a player has made a vote which wasn't matched to an alive player correctly, the host can fix it in the votecount. For example, an incorrect votecount:
```
[votecount]
Player3 (1): Player1
Palyer3 (1): Player2

Not Voting (1): Player3
[/votecount]
```

In this example, Player2 has typoed their vote for Player3, and so it's being shown separately. The host can remove the line for "Payler3" and add Player2 to the list voting for Player3, and the votecount will be corrected from the manual votecount onwards.

Secondly, if a game is fast moving, the votecounter might slow down while parsing posts and looking for votes. As the votecounter only looks back as far as required to get a full picture, the host posting a manual votecount reduces the number of posts it must process and reduces wait time.


## Required BBcode for use off Mafia451

This guide refers to BBcode tags used on Mafia451, so here's a list of HTML definitions. If you want to use this votecounter, I'd recommend setting these BBcode tags up on your site.

### [alive] tags

```
[alive]
@Player1
@Player2
@Player3
[/alive]
```

```
<div class="alive">
<!-- List of @ mentioned players -->  
</div>
```

### [votecount] tags

```
[votecount]
Player3 (2): Player1, Player2

Not Voting (1): Player3
[/votecount]
```

```
<div class="votecount">
<!-- Correctly formatted votecount -->  
</div>
```

### [vote] tags

```
[vote]Player1[/vote]
```

```
<span class="vote">VOTE: Player1</span>
```


### [unvote] tags

```
[unvote][/unvote]
```

```
<span class="vote">UNVOTE</span>
```

# Votecount Per Post
A Discourse plugin for playing forum mafia, which shows who each user is voting for as of each post (except the topic poster).

It requires votes, unvotes and vote resets to be formatted correctly using `<span class="vote"></span>` to be picked up.



To vote a player: `<span class="vote">VOTE: [player]</span>`

This will show as 

**User** is voting **[player]**


To remove a vote: `<span class="vote">UNVOTE</span>`

**User** is voting **no one**


To reset all votes: `<span class="vote">RESET</span>`




The plugin will ignore all other actions in a post with a RESET, otherwise it will take the most recent action. The user who posted a topic will not show in the votecount but are able to reset posts with RESET.

All posters (except the topic poster) who have made a post since the topic beginning or a RESET post will be listed in the votecount.


Developed for [Mafia451](https://forum.mafia451.com/) - click on the gavel icon on a post.

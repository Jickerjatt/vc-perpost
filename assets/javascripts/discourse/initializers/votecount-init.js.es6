import { withPluginApi } from 'discourse/lib/plugin-api'
import Votecount from '../lib/votecount'
import AppController from 'discourse/controllers/application';
import showModal from 'discourse/lib/show-modal';
import sweetalert from '../lib/sweetalert2/dist/sweetalert2'

function initializePlugin(api) {

  api.addPostMenuButton('votecount', attrs => {

    return {
      action: 'showVotecount',
      icon: 'gavel',
      title: 'votecount.title',
      position: 'first'
    }
  })


 api.attachWidgetAction('post-menu', 'showVotecount', function() {
    var post_number = this.attrs.post_number;
    Votecount.getVotecount(this.attrs.topicId, post_number).then(function(vcJson) {

      var alive_players = vcJson.alive;

      // reformat array

      var vc_arr = getVotecountArr(vcJson.votecount, alive_players);


      // create html

      var vc_title = "Votecount as of post #" + post_number;
      var vc = getVotecountHtml(vc_arr);


      sweetalert({
        title: vc_title,
        html: vc,
        confirmButtonColor: '#3085d6',
        confirmButtonText: 'List View',
        showCancelButton: true,
        cancelButtonText: 'Close',
      }).then((result) => {
        if (result.value) {

          // create html

          var votes_title   = "Votes as of post #" + post_number;
          var votes         = getVotesHtml(vcJson.votecount);

          sweetalert({
            html: votes,
            title: votes_title,
            confirmButtonColor: '#3085d6',
            confirmButtonText: 'Classic View',
            showCancelButton: true,
            cancelButtonText: 'Close',
          }).then((result) => {
            if (result.value) {

              // reformat array

              var vc_arr = getVotecountArr(vcJson.votecount, alive_players);


              // create html

              var vc_title = "Votecount as of post #" + post_number;
              var vc = getVotecountHtml(vc_arr);


              sweetalert({
                title: vc_title,
                html: vc,
                confirmButtonColor: '#3085d6',
                confirmButtonText: 'List View',
                showCancelButton: true,
                cancelButtonText: 'Close',
              }).then((result) => {
                if (result.value) {

                  // create html

                  var votes_title  = "Votes as of post #" + post_number;
                  var votes = getVotesHtml(vcJson.votecount);


                  sweetalert({
                      html: votes,
                      title: votes_title,
                      confirmButtonColor: '#3085d6',
                      confirmButtonText: 'Classic View',
                      showCancelButton: true,
                      cancelButtonText: 'Close',
                  }).then((result) => {
                    if (result.value) {

                      // reformat array

                      var vc_arr = getVotecountArr(vcJson.votecount, alive_players);


                      // create html

                      var vc_title = "Votecount as of post #" + post_number;
                      var vc = getVotecountHtml(vc_arr);


                      sweetalert({
                        title: vc_title,
                        html: vc,
                        showConfirmButton: false,
                        showCancelButton: true,
                        cancelButtonText: 'That\'s all for now!',
                      });
                    }
                  });
                }
              });
            }
          });
        }
      });
    });
  });
}


function getVotecountArr(votes_arr, alive_players){
  // restructure array of votes into votee: [voter, voter, voter]
  // note that one voter can be voting multiple votees

  var vc_arr = [];

  for (var i = 0 ; i < votes_arr.length ; i++){
    var voter = votes_arr[i].voter;
    var votes = votes_arr[i].votes;

    for (var j = 0 ; j < votes.length ; j++){
      var votee   = transformMalformedVote(votes[j], alive_players);
      var exists  = false;


      // go through vc_arr to see if votee is present

      for (var k = 0 ; k < vc_arr.length ; k++){
        if(standardiseVote(vc_arr[k]['votee']) === standardiseVote(votee)){
          var voters = vc_arr[k]['voters']
          if(!voters.includes(voter)) {voters.push(voter);} // only add if voter isn't already there
          exists = true;
        }
      }

      // if votee is not already in array, insert object with votee and voters as keys

      if(!exists){
        vc_arr.push({'votee': votee, 'voters': [voter]});
      }
    }
  }


  // return array of votes in order of most voters to least

  vc_arr = vc_arr.sort(function(a, b) {return (b['voters'].length - a['voters'].length)});

  return(vc_arr);
}


function getVotesHtml(votes_arr){
  // get list of votes in html format

  var votes = "";

  for (var i = 0 ; i < votes_arr.length ; i++){
    var voter = votes_arr[i].voter;
    var votee = votes_arr[i].votes.join(', ');
    var post  = votes_arr[i].post;
    if(votee == 'NO_VOTE'){
      votee = 'no one';
    }
    if(post){
      votes += "<br/><b>" + voter + "</b>" + " is voting " + "<b>" + votee + "</b> (post #" + post + ")";
    }
    else{
      votes += "<br/><b>" + voter + "</b>" + " is voting " + "<b>" + votee + "</b>";
    }
  }

  return(votes);
}


function getVotecountHtml(vc_arr){
  // get classic votecount html from vc_arr

  var vc = "<div align=left>";
  var not_voting;

  for (var i = 0 ; i < vc_arr.length ; i++) {
    var line = vc_arr[i];

    if(line['votee'] == 'NO_VOTE'){

      // remember this item and skip for now
      not_voting = line['voters'];

    }
    else{

      var voters  = line['voters'];
      var votee   = line['votee'];

      vc += "<br/><b>" + votee + " (" + voters.length + "):</b>";

      for (var j = 0 ; j < voters.length-1 ; j++){
        vc += " " + voters[j] + ",";
      }

      vc += " " + voters[voters.length - 1];
    }
  }
  if(not_voting){
    vc += "<br/><br/><b>Not Voting (" + not_voting.length + "):</b>";

    for (var i = 0 ; i < not_voting.length-1 ; i++){
      vc += " " + not_voting[i] + ",";
    }

    vc += " " + not_voting[not_voting.length - 1];
  }

  vc += "</div>";

  return(vc);
}

function transformMalformedVote(vote, alive_players) {
  // check if a vote is supposed to be for a living player, and if so return the correct player name

  for (var i = 0 ; i < alive_players.length ; i++){
      if(standardiseVote(alive_players[i]) === standardiseVote(vote)){
        return(alive_players[i]);
      }
  }

  // check if the vote is a substring of any valid players

  for (var i = 0 ; i < alive_players.length ; i++){
      if(standardiseVote(alive_players[i]).includes(standardiseVote(vote))){
        return(alive_players[i]);
      }
  }

  // if no matches, leave the vote as is
  return(vote);
}

function standardiseVote(vote) {
  // lowercase, strip out spaces and @ symbol for comparing votes against each other
  return(vote.toLowerCase().replace(/\s/g,'').replace(/@/g,''))
}


export default {
  name: 'votecount-button',
  initialize: function(container) {
    withPluginApi('0.8.6', api => initializePlugin(api, container))
  }
}

import { withPluginApi } from 'discourse/lib/plugin-api'
import TopicRoute from 'discourse/routes/topic'
import Votecount from '../lib/votecount'
import AppController from 'discourse/controllers/application';
import showModal from 'discourse/lib/show-modal';
import sweetalert from '../lib/sweetalert2/dist/sweetalert2'
import { ajax } from 'discourse/lib/ajax';

function initializePlugin(api) {
  let topicController;

  TopicRoute.on("setupTopicController", function(event) {
    topicController = event.controller
  })

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
      var vc = "Votes as of post #" + post_number + ":";
      for (var i = 0 ; i < vcJson.votecount.length ; i++){
        vc += "\n" +vcJson.votecount[i].voter + " is voting " + vcJson.votecount[i].votee;
      }
      sweetalert({
  title: "Hi",
  text: "Hi!" 
 });
    });
  })
}

export default {
  name: 'votecount-button',
  initialize: function() {
    withPluginApi('0.8.6', api => initializePlugin(api))
  }
}

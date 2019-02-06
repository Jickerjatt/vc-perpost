import { withPluginApi } from 'discourse/lib/plugin-api'
import TopicRoute from 'discourse/routes/topic'
import Votecount from '../lib/votecount'


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
    Votecount.getVotecount(this.attrs.topicId, this.attrs.post_number).then(function(vcJson) {
      var vc = "";
      for (var i = 0 ; i < vcJson.votecount.length ; i++){
        vc += "\n" +vcJson.votecount[i].voter + " is voting " + vcJson.votecount[i].votee;
      }
      alert(vc);
    });
  })
}

export default {
  name: 'votecount-button',
  initialize: function() {
    withPluginApi('0.8.6', api => initializePlugin(api))
  }
}

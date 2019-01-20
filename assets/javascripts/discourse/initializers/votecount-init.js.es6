import { withPluginApi } from 'discourse/lib/plugin-api'
import TopicRoute from 'discourse/routes/topic'
import Votecount from '../lib/votecount'

function initializePlugin(api) {
let topicController;

  TopicRoute.on("setupTopicController", function(event) {
    topicController = event.controller
  })

  api.addPostMenuButton('alert', attrs => {

    return {
      action: 'clickAlert',
      icon: 'bath',
      title: 'alert.title',
      position: 'last'
    }
  })

  api.attachWidgetAction('post-menu', 'clickAlert', function() {
    Votecount.getVotecount(this.attrs.id).then(function(vcJson)
    {
      alert(
        'Votee: ' + vcJson.Votee[0] + ', ' + vcJson.Votee[1] + ', ' + vcJson.Votee[2]);
    });
  })
}

export default {
  name: 'alert-button',
  initialize: function() {
    withPluginApi('0.8.6', api => initializePlugin(api))
  }
}

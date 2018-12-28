import { withPluginApi } from 'discourse/lib/plugin-api'
import TopicRoute from 'discourse/routes/topic'

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
    alert('topic title: ' + topicController.get("model.title") + '\npost number: ' + this.attrs.post_number + '\npost id: ' + this.attrs.id );
  })
}

export default {
  name: 'alert-button',
  initialize: function() {
    withPluginApi('0.8.6', api => initializePlugin(api))
  }
}

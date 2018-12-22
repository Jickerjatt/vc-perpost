import { withPluginApi } from 'discourse/lib/plugin-api'
import TopicRoute from 'discourse/routes/topic'

function initializePlugin(api) {
  // I think this is where code needs to be written to make a call to an API function which accepts a post_id and returns HTML, and inject that into the share-popup component.
}

export default {
  name: 'iso-button',
  initialize: function() {
    withPluginApi('0.8.6', api => initializePlugin(api))
  }
}

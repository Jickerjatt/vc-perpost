import { withPluginApi } from 'discourse/lib/plugin-api'
import Votecount from '../lib/votecount'
import showModal from 'discourse/lib/show-modal';

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
      showModal("votecount", {
        model: {
            post_number: post_number,
            votecount: vcJson.votecount,
            alive: vcJson.alive,
            vcView: "classic" // set to classic votecount by default
        }
      });
    });
  });
}


export default {
  name: 'votecount-button',
  initialize: function(container) {
    withPluginApi('0.8.6', api => initializePlugin(api, container))
  }
}

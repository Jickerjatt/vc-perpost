import { withPluginApi } from 'discourse/lib/plugin-api'
import Votecount from '../lib/votecount'
import AppController from 'discourse/controllers/application';
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

      console.log(vcJson);

      var vc_title = "Votecount as of post #" + post_number;
      var vc        = "what up it's ya boiii";

      let controller = showModal("votecount", {
        model: {
            title: vc_title,
            html: vc,
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

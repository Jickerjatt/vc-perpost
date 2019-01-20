import { ajax } from 'discourse/lib/ajax'
import { popupAjaxError } from "discourse/lib/ajax-error";

export default Ember.Object.create({

  getVotecount(postId) {
    return ajax(`/votecount/${postId}.json`, {
      type: 'POST'
    }).catch(popupAjaxError)
  }
})
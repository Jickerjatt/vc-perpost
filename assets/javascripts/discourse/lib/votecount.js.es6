import { ajax } from 'discourse/lib/ajax'
import { popupAjaxError } from "discourse/lib/ajax-error";

export default Ember.Object.create({

  getVotecount(topicId, postNumber) {
    return ajax(`/votecount/${topicId}/${postNumber}.json`, {
      type: 'GET'
    }).catch(popupAjaxError)
  }
})
import { Controller } from "@hotwired/stimulus"
import Plyr from "plyr"

export default class extends Controller {
  connect() {
    this.player = new Plyr(this.element, {
      controls: [
        "play-large", "play", "progress", "current-time", "duration",
        "mute", "volume", "captions", "fullscreen"
      ],
      autoplay: false,
      muted: false,
      resetOnEnd: false,
      keyboard: { focused: true, global: false },
      tooltips: { controls: true, seek: true },
      captions: { active: false },
    })
  }

  disconnect() {
    this.player?.destroy()
  }
}

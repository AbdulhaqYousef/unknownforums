import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Plyr is loaded as a UMD global via <script> tag before importmap
    if (typeof window.Plyr === "undefined") {
      console.warn("Plyr not loaded yet — video player unavailable")
      return
    }
    requestAnimationFrame(() => {
      this.player = new window.Plyr(this.element, {
        controls: [
          "play-large", "play", "progress", "current-time", "duration",
          "mute", "volume", "captions", "fullscreen"
        ],
        autoplay:    false,
        muted:       false,
        resetOnEnd:  false,
        keyboard:    { focused: true, global: false },
        tooltips:    { controls: true, seek: true },
        captions:    { active: false },
        ratio:       undefined,
        loadSprite:  false,
        iconUrl:     "https://cdn.jsdelivr.net/npm/plyr@3.7.8/dist/plyr.svg",
      })
    })
  }

  disconnect() {
    this.player?.destroy()
    this.player = null
  }
}

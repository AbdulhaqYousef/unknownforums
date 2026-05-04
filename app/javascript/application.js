// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

function siteConfirm(message, options = {}) {
  const modal = document.getElementById("site-confirm-modal")
  const messageEl = document.getElementById("site-confirm-message")
  const okButton = document.getElementById("site-confirm-ok")
  const cancelButton = document.getElementById("site-confirm-cancel")

  if (!modal || !messageEl || !okButton || !cancelButton) return Promise.resolve(false)

  messageEl.textContent = message || "Are you sure?"
  okButton.textContent = options.confirmText || "Confirm"
  cancelButton.textContent = options.cancelText || "Cancel"
  cancelButton.style.display = options.alert ? "none" : ""
  okButton.className = options.danger === false ? "btn btn-primary" : "btn btn-danger"
  modal.classList.add("active")
  modal.setAttribute("aria-hidden", "false")
  okButton.focus()

  return new Promise((resolve) => {
    let resolved = false
    const finish = (value) => {
      if (resolved) return
      resolved = true
      modal.classList.remove("active")
      modal.setAttribute("aria-hidden", "true")
      cancelButton.style.display = ""
      okButton.removeEventListener("click", confirm)
      cancelButton.removeEventListener("click", cancel)
      modal.removeEventListener("click", backdrop)
      document.removeEventListener("keydown", keydown)
      resolve(value)
    }
    const confirm = () => finish(true)
    const cancel = () => finish(false)
    const backdrop = (event) => {
      if (event.target === modal) cancel()
    }
    const keydown = (event) => {
      if (event.key === "Escape") cancel()
    }

    okButton.addEventListener("click", confirm)
    cancelButton.addEventListener("click", cancel)
    modal.addEventListener("click", backdrop)
    document.addEventListener("keydown", keydown)
  })
}

window.siteConfirm = siteConfirm
window.siteAlert = (message) => siteConfirm(message, { alert: true, danger: false, confirmText: "OK" })

let _appBootDone = false
document.addEventListener("turbo:load", () => {
  if (window.Turbo) {
    window.Turbo.config.forms.confirm = (message) => siteConfirm(message)
    window.Turbo.config.drive.prefetch = false
  }
  if (!_appBootDone) {
    _appBootDone = true
    initLightbox()
  }
  initMentionAutocomplete()
  initFileUpload()
  initVideoJS()
})

/* ── Video.js player init ── */
function initVideoJS() {
  if (typeof window.videojs === "undefined") return
  document.querySelectorAll("video.video-js").forEach(el => {
    if (el._vjsInit) return
    el._vjsInit = true
    window.videojs(el, {
      fluid: true,
      responsive: true,
      playbackRates: [0.5, 1, 1.25, 1.5, 2],
      controlBar: {
        children: [
          "playToggle", "volumePanel", "currentTimeDisplay", "timeDivider",
          "durationDisplay", "progressControl", "playbackRateMenuButton",
          "fullscreenToggle"
        ]
      }
    })
  })
}

/* ── File upload drop zone ── */
function initFileUpload() {
  const zone  = document.getElementById("file-drop-zone")
  const input = document.getElementById("file-upload-input")
  if (!zone || !input || zone._init) return
  zone._init = true

  zone.addEventListener("click", () => input.click())

  let dragCounter = 0
  zone.addEventListener("dragenter", (e) => {
    e.preventDefault(); e.stopPropagation()
    if (++dragCounter === 1) { zone.style.borderColor = "#3d9faf"; zone.style.background = "rgba(61,159,175,0.06)" }
  })
  zone.addEventListener("dragleave", (e) => {
    e.preventDefault(); e.stopPropagation()
    if (--dragCounter <= 0) { dragCounter = 0; zone.style.borderColor = "#444"; zone.style.background = "" }
  })
  zone.addEventListener("dragover", (e) => { e.preventDefault(); e.stopPropagation() })
  zone.addEventListener("drop", (e) => {
    e.preventDefault(); e.stopPropagation()
    dragCounter = 0; zone.style.borderColor = "#444"; zone.style.background = ""
    const dropped = Array.from(e.dataTransfer.files)
    if (!dropped.length) return
    const dt = new DataTransfer()
    Array.from(input.files).forEach(f => dt.items.add(f))
    dropped.forEach(f => dt.items.add(f))
    input.files = dt.files
    renderFilePreview(input.files)
  })
  input.addEventListener("change", function() { renderFilePreview(this.files) })
}

function renderFilePreview(files) {
  const label   = document.getElementById("file-list-label")
  const preview = document.getElementById("file-preview-list")
  if (!label || !preview) return
  preview.innerHTML = ""
  if (!files.length) { label.textContent = ""; return }
  label.textContent = files.length + " file" + (files.length !== 1 ? "s" : "") + " selected"
  Array.from(files).forEach(file => {
    const isImg = file.type.startsWith("image/")
    const isVid = file.type.startsWith("video/")
    const tag   = isImg ? "IMG" : isVid ? "VID" : "FILE"
    const size  = file.size >= 1048576 ? (file.size/1048576).toFixed(1)+" MB" : (file.size/1024).toFixed(0)+" KB"
    const row   = document.createElement("div")
    row.style.cssText = "font-size:10px;color:#888;padding:2px 0;display:flex;align-items:center;gap:6px;"
    row.innerHTML = `<span style="border:1px solid #555;padding:1px 4px;font-size:9px;color:#aaa;">${tag}</span>`
      + `<span style="color:#a8c8f0;">${file.name}</span>`
      + `<span style="color:#555;">(${size})</span>`
    if (isImg) {
      const img = document.createElement("img")
      img.style.cssText = "height:36px;width:auto;border:1px solid #333;margin-left:2px;"
      img.src = URL.createObjectURL(file)
      row.appendChild(img)
    }
    preview.appendChild(row)
  })
}

/* ── Image lightbox ── */
function initLightbox() {
  const overlay = document.createElement("div")
  overlay.id = "img-lightbox"
  overlay.style.cssText = "display:none;position:fixed;inset:0;z-index:9999;background:rgba(0,0,0,0.88);align-items:center;justify-content:center;cursor:zoom-out;"
  overlay.innerHTML = '<img id="img-lightbox-img" style="max-width:94vw;max-height:92vh;border-radius:3px;box-shadow:0 8px 40px rgba(0,0,0,0.7);">'
  document.body.appendChild(overlay)

  document.addEventListener("click", (e) => {
    const img = e.target.closest("[data-lightbox-src]")
    if (img) {
      document.getElementById("img-lightbox-img").src = img.dataset.lightboxSrc
      overlay.style.display = "flex"
      return
    }
    if (e.target === overlay || e.target.id === "img-lightbox-img") {
      overlay.style.display = "none"
    }
  })

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") overlay.style.display = "none"
  })
}

/* ── @mention autocomplete ── */
function initMentionAutocomplete() {
  // Remove any leftover dropdown from a previous page
  const old = document.getElementById("mention-dropdown")
  if (old) old.remove()

  const dropdown = document.createElement("ul")
  dropdown.id = "mention-dropdown"
  dropdown.style.cssText = [
    "position:absolute", "z-index:9000", "background:#1e1e1e",
    "border:1px solid #3d9faf", "border-radius:3px", "margin:0", "padding:0",
    "list-style:none", "min-width:180px", "max-width:260px",
    "box-shadow:0 4px 16px rgba(0,0,0,0.5)", "display:none", "font-size:12px",
    "font-family:Verdana,Arial,sans-serif"
  ].join(";")
  document.body.appendChild(dropdown)

  let activeIndex  = -1
  let currentInput = null
  let mentionStart = -1
  let debounceTimer = null

  function positionDropdown(textarea) {
    // Approximate caret position using a mirror div
    const style   = window.getComputedStyle(textarea)
    const mirror  = document.createElement("div")
    const props   = ["boxSizing","width","height","overflowX","overflowY",
                     "borderTopWidth","borderRightWidth","borderBottomWidth","borderLeftWidth",
                     "paddingTop","paddingRight","paddingBottom","paddingLeft",
                     "fontStyle","fontVariant","fontWeight","fontStretch","fontSize",
                     "lineHeight","fontFamily","textAlign","letterSpacing","wordSpacing"]
    mirror.style.cssText = "position:absolute;visibility:hidden;white-space:pre-wrap;word-wrap:break-word;"
    props.forEach(p => mirror.style[p] = style[p])
    mirror.style.width = textarea.offsetWidth + "px"
    document.body.appendChild(mirror)

    const text   = textarea.value.substring(0, textarea.selectionEnd)
    const span   = document.createElement("span")
    mirror.textContent = text
    mirror.appendChild(span)
    span.textContent = "."

    const rect   = textarea.getBoundingClientRect()
    const sRect  = span.getBoundingClientRect()
    const mRect  = mirror.getBoundingClientRect()
    document.body.removeChild(mirror)

    const top  = rect.top  + window.scrollY + (sRect.top  - mRect.top)  + parseInt(style.lineHeight || 16) + 2
    const left = rect.left + window.scrollX + (sRect.left - mRect.left)
    dropdown.style.top  = top  + "px"
    dropdown.style.left = left + "px"
  }

  function closeDropdown() {
    dropdown.style.display = "none"
    dropdown.innerHTML = ""
    activeIndex = -1
  }

  function setActive(index) {
    const items = dropdown.querySelectorAll("li")
    items.forEach((li, i) => {
      li.style.background = i === index ? "#2a7080" : ""
      li.style.color      = i === index ? "#fff" : "#d0d0d0"
    })
    activeIndex = index
  }

  function insertMention(username, textarea) {
    const before = textarea.value.substring(0, mentionStart)
    const after  = textarea.value.substring(textarea.selectionEnd)
    textarea.value = before + "@" + username + " " + after
    const pos = mentionStart + username.length + 2
    textarea.setSelectionRange(pos, pos)
    textarea.focus()
    closeDropdown()
  }

  function fetchSuggestions(query, textarea) {
    if (!query) return closeDropdown()
    clearTimeout(debounceTimer)
    debounceTimer = setTimeout(() => {
      fetch("/users/search?q=" + encodeURIComponent(query), {
        headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" }
      })
      .then(r => r.json())
      .then(users => {
        if (!users.length) return closeDropdown()
        dropdown.innerHTML = ""
        activeIndex = -1
        users.forEach((u, i) => {
          const li = document.createElement("li")
          li.style.cssText = "padding:6px 10px;cursor:pointer;color:#d0d0d0;display:flex;align-items:center;gap:6px;"
          li.innerHTML = `<span style="color:#3d9faf;font-weight:bold;">@</span>${u.username}`
          li.addEventListener("mousedown", e => {
            e.preventDefault()
            insertMention(u.username, textarea)
          })
          li.addEventListener("mouseenter", () => setActive(i))
          dropdown.appendChild(li)
        })
        positionDropdown(textarea)
        dropdown.style.display = "block"
      })
      .catch(() => closeDropdown())
    }, 120)
  }

  document.addEventListener("input", e => {
    const ta = e.target
    if (ta.tagName !== "TEXTAREA") return
    currentInput = ta

    const caret  = ta.selectionEnd
    const text   = ta.value.substring(0, caret)
    const match  = text.match(/@([A-Za-z0-9_\-]{0,30})$/)

    if (match) {
      mentionStart = caret - match[0].length
      fetchSuggestions(match[1], ta)
    } else {
      closeDropdown()
    }
  }, true)

  document.addEventListener("keydown", e => {
    if (dropdown.style.display === "none") return
    const items = dropdown.querySelectorAll("li")
    if (!items.length) return

    if (e.key === "ArrowDown") {
      e.preventDefault()
      setActive(Math.min(activeIndex + 1, items.length - 1))
    } else if (e.key === "ArrowUp") {
      e.preventDefault()
      setActive(Math.max(activeIndex - 1, 0))
    } else if (e.key === "Enter" || e.key === "Tab") {
      if (activeIndex >= 0) {
        e.preventDefault()
        const username = items[activeIndex].textContent.trim()
        insertMention(username, currentInput)
      } else if (e.key === "Tab") {
        closeDropdown()
      }
    } else if (e.key === "Escape") {
      closeDropdown()
    }
  }, true)

  document.addEventListener("click", e => {
    if (!dropdown.contains(e.target)) closeDropdown()
  })

  document.addEventListener("scroll", () => {
    if (dropdown.style.display !== "none" && currentInput) positionDropdown(currentInput)
  }, true)
}

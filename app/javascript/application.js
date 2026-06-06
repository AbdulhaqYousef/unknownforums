// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import { DirectUpload } from "@rails/activestorage"
import "controllers"

document.addEventListener("turbo:load", () => {
  if (document.querySelector("meta[name='turbo-clear-cache']")) {
    Turbo.clearCache()
  }
})

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
  initFileUploadForms()
  initVideoJS()
  initCategoryToggle()
  initBulkPosts()
  initQuotePost()
  initAdminThreadBulk()
})

/* ── Category collapse ── */
function initCategoryToggle() {
  const meta = document.getElementById("category-ids")
  if (meta) {
    let ids = []
    try { ids = JSON.parse(meta.textContent) } catch(e) {}
    ids.forEach(id => {
      if (localStorage.getItem("cat-collapsed-" + id) === "1") {
        const body    = document.getElementById("cat-body-" + id)
        const chevron = document.getElementById("cat-chevron-" + id)
        if (body)    body.style.display = "none"
        if (chevron) chevron.style.transform = "rotate(-90deg)"
      }
    })
  }
  document.querySelectorAll("[data-category-id]").forEach(btn => {
    if (btn._catInit) return
    btn._catInit = true
    btn.addEventListener("click", () => {
      const id      = btn.dataset.categoryId
      const body    = document.getElementById("cat-body-" + id)
      const chevron = document.getElementById("cat-chevron-" + id)
      const key     = "cat-collapsed-" + id
      if (body.style.display === "none") {
        body.style.display = ""
        chevron.style.transform = ""
        localStorage.removeItem(key)
      } else {
        body.style.display = "none"
        chevron.style.transform = "rotate(-90deg)"
        localStorage.setItem(key, "1")
      }
    })
  })
}

/* ── Bulk post delete ── */
let _bulkPostsInit = false
function initBulkPosts() {
  if (_bulkPostsInit) return
  _bulkPostsInit = true

  function updateBulkBar() {
    const bar     = document.getElementById("bulk-delete-bar")
    const count   = document.getElementById("bulk-count")
    if (!bar || !count) return
    const checked = document.querySelectorAll(".bulk-check:checked").length
    count.textContent = checked + " post" + (checked === 1 ? "" : "s") + " selected"
    bar.style.display = checked > 0 ? "flex" : "none"
  }

  document.addEventListener("change", (e) => {
    if (e.target.classList.contains("bulk-check")) updateBulkBar()
  })

  document.addEventListener("click", (e) => {
    if (e.target.id === "bulk-select-all-posts") {
      document.querySelectorAll(".bulk-check").forEach(cb => cb.checked = true)
      updateBulkBar()
    }
    if (e.target.id === "bulk-deselect-all-posts") {
      document.querySelectorAll(".bulk-check").forEach(cb => cb.checked = false)
      updateBulkBar()
    }
  })

  document.addEventListener("submit", async (e) => {
    const form = e.target
    if (form.id !== "bulk-delete-form") return
    const checked = document.querySelectorAll(".bulk-check:checked").length
    if (checked === 0) {
      e.preventDefault()
      await window.siteAlert("No posts selected.")
      return
    }
    if (!form.dataset.confirmed) {
      e.preventDefault()
      if (await window.siteConfirm("Delete " + checked + " post" + (checked === 1 ? "" : "s") + "? This cannot be undone.")) {
        form.dataset.confirmed = "1"
        form.requestSubmit()
      }
      return
    }
    delete form.dataset.confirmed
  })

  document.addEventListener("turbo:load", () => {
    document.querySelectorAll(".bulk-check").forEach(cb => cb.checked = false)
    const bar = document.getElementById("bulk-delete-bar")
    if (bar) bar.style.display = "none"
  })
}

/* ── Quote post (delegated, once) ── */
let _quotePostInit = false
function initQuotePost() {
  if (_quotePostInit) return
  _quotePostInit = true
  document.addEventListener("click", (e) => {
    const link = e.target.closest("[data-quote-post-id]")
    if (!link) return
    e.preventDefault()
    const postId  = link.dataset.quotePostId
    const field   = document.getElementById("quote_post_id_field")
    const preview = document.getElementById("quote-preview")
    const form    = document.getElementById("reply-form")
    if (!field) return
    field.value = postId
    if (preview) { preview.style.display = "block"; preview.textContent = "Quoting post #" + postId }
    if (form)    form.scrollIntoView({ behavior: "smooth" })
  })
}

/* ── Admin thread bulk actions ── */
function initAdminThreadBulk() {
  const bulkForm = document.getElementById("bulk-form")
  if (!bulkForm || bulkForm._init) return
  bulkForm._init = true

  document.getElementById("bulk-select-all")?.addEventListener("click",   () => document.querySelectorAll(".bulk-cb").forEach(cb => cb.checked = true))
  document.getElementById("bulk-deselect-all")?.addEventListener("click", () => document.querySelectorAll(".bulk-cb").forEach(cb => cb.checked = false))

  bulkForm.querySelector("select[name='bulk_action']")?.addEventListener("change", function() {
    const mt = document.getElementById("move-target")
    if (mt) mt.style.display = this.value === "move" ? "inline-block" : "none"
  })

  bulkForm.addEventListener("submit", async (event) => {
    const action = bulkForm.querySelector("select[name='bulk_action']")?.value
    const count  = document.querySelectorAll(".bulk-cb:checked").length
    if (!action) { event.preventDefault(); await window.siteAlert("Please select an action."); return }
    if (!count)  { event.preventDefault(); await window.siteAlert("Please select at least one thread."); return }
    if (action === "delete" && !bulkForm.dataset.confirmed) {
      event.preventDefault()
      if (await window.siteConfirm("Delete " + count + " thread(s)? This cannot be undone.")) {
        bulkForm.dataset.confirmed = "1"
        bulkForm.requestSubmit()
      }
    }
  })
}

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
function maxFileBytes() {
  const zone = document.getElementById("file-drop-zone")
  const raw  = zone ? parseInt(zone.dataset.maxBytes, 10) : NaN
  return Number.isFinite(raw) && raw > 0 ? raw : 500 * 1024 * 1024
}

function maxFileLabel() {
  return fmtSize(maxFileBytes())
}

function fileKey(file) {
  return `${file.name}:${file.size}:${file.lastModified}`
}

function initFileUpload() {
  const zone  = document.getElementById("file-drop-zone")
  const input = document.getElementById("file-upload-input")
  if (!zone || !input || zone._init) return
  zone._init = true
  zone._uploads = new Map()

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
    handleSelectedFiles(input)
  })
  input.addEventListener("change", function() { handleSelectedFiles(this) })
}

function handleSelectedFiles(input) {
  const zone = document.getElementById("file-drop-zone")
  if (zone && zone.dataset.directUpload === "true") {
    queueDirectUploads(input)
  }
  renderFilePreview(input.files)
}

function queueDirectUploads(input) {
  const zone = document.getElementById("file-drop-zone")
  if (!zone) return

  Array.from(input.files).forEach(file => {
    const key = fileKey(file)
    if (file.size > maxFileBytes()) return
    if (zone._uploads.has(key) && zone._uploads.get(key).status !== "error") return

    zone._uploads.set(key, { status: "uploading", progress: 0, signedId: null, error: null })
    renderFilePreview(input.files)

    const delegate = {
      directUploadWillStoreFileWithXHR(xhr) {
        xhr.upload.addEventListener("progress", (event) => {
          if (!event.lengthComputable) return
          const entry = zone._uploads.get(key)
          if (!entry) return
          entry.progress = event.loaded / event.total
          renderFilePreview(input.files)
        })
      }
    }

    const upload = new DirectUpload(file, "/rails/active_storage/direct_uploads", delegate)
    upload.create((error, blob) => {
      const entry = zone._uploads.get(key)
      if (!entry) return
      if (error) {
        entry.status = "error"
        entry.error = error
      } else {
        entry.status = "done"
        entry.progress = 1
        entry.signedId = blob.signed_id
      }
      renderFilePreview(input.files)

      const form = input.closest("form")
      if (form?._awaitingSubmit && directUploadState().pending === 0 && directUploadState().errors.length === 0) {
        form._awaitingSubmit = false
        form.requestSubmit()
      }
    })
  })
}

function directUploadState() {
  const zone = document.getElementById("file-drop-zone")
  if (!zone || zone.dataset.directUpload !== "true") return { enabled: false, pending: 0, errors: [] }

  const entries = Array.from(zone._uploads?.values() || [])
  return {
    enabled: true,
    pending: entries.filter(e => e.status === "uploading").length,
    errors: entries.filter(e => e.status === "error"),
    signedIds: entries.filter(e => e.status === "done" && e.signedId).map(e => e.signedId)
  }
}

function setUploadStatus(message, tone) {
  const box = document.getElementById("file-upload-status")
  if (!box) return
  if (!message) {
    box.style.display = "none"
    box.textContent = ""
    return
  }
  box.style.display = "block"
  box.style.color = tone === "error" ? "#f08080" : "#8fd0d8"
  box.style.background = tone === "error" ? "#3a1a1a" : "#1a2a2a"
  box.style.borderColor = tone === "error" ? "#6a2a2a" : "#2a4a4a"
  box.textContent = message
}

function prepareDirectUploadForm(form) {
  const holder = document.getElementById("file-signed-ids")
  const input  = document.getElementById("file-upload-input")
  if (holder) holder.innerHTML = ""

  directUploadState().signedIds.forEach((signedId) => {
    const hidden = document.createElement("input")
    hidden.type = "hidden"
    hidden.name = "file_signed_ids[]"
    hidden.value = signedId
    ;(holder || form).appendChild(hidden)
  })

  if (input) {
    input.removeAttribute("name")
    input.value = ""
  }
}

let _fileUploadFormsInit = false
function initFileUploadForms() {
  if (_fileUploadFormsInit) return
  _fileUploadFormsInit = true

  document.addEventListener("submit", async (event) => {
    const form = event.target
    if (form.dataset.directUploadReady === "1") {
      delete form.dataset.directUploadReady
      return
    }

    const input = form.querySelector("#file-upload-input")
    if (!input || !input.files.length) return

    const zone = document.getElementById("file-drop-zone")
    const usesDirectUpload = zone && zone.dataset.directUpload === "true"

    if (usesDirectUpload) {
      event.preventDefault()
      const state = directUploadState()
      if (state.errors.length) {
        setUploadStatus("Some files failed to upload. Remove them and try again.", "error")
        return
      }
      if (state.pending > 0) {
        form._awaitingSubmit = true
        setUploadStatus("Still uploading to storage — please wait…", "info")
        return
      }

      prepareDirectUploadForm(form)
      setUploadStatus("Finishing post…", "info")
      form.querySelectorAll("[type=submit]").forEach(btn => { btn.disabled = true })
      form.dataset.directUploadReady = "1"
      form.submit()
      return
    }

    const oversized = Array.from(input.files).filter(f => f.size > maxFileBytes())
    if (oversized.length) {
      event.preventDefault()
      return
    }

    setUploadStatus("Uploading — keep this page open until it finishes.", "info")
    form.querySelectorAll("[type=submit]").forEach(btn => { btn.disabled = true })
  })
}

function renderFilePreview(files) {
  const label   = document.getElementById("file-list-label")
  const preview = document.getElementById("file-preview-list")
  const errBox  = document.getElementById("file-size-error")
  if (!label || !preview) return

  preview.innerHTML = ""
  if (errBox) { errBox.style.display = "none"; errBox.innerHTML = "" }

  if (!files.length) {
    label.textContent = "No files selected"
    setUploadStatus("", "info")
    return
  }

  const limit = maxFileBytes()
  const oversized = Array.from(files).filter(f => f.size > limit)
  const input     = document.getElementById("file-upload-input")
  const form      = input ? input.closest("form") : null
  const uploads   = directUploadState()

  if (oversized.length) {
    if (errBox) {
      errBox.style.display = "block"
      errBox.innerHTML = "<strong>File size exceeded (" + maxFileLabel() + " limit):</strong><ul style='margin:3px 0 0 14px;padding:0;'>"
        + oversized.map(f => `<li>${f.name} — ${fmtSize(f.size)}</li>`).join("")
        + "</ul>"
    }
    if (form) form.querySelectorAll("[type=submit]").forEach(btn => { btn.disabled = true; btn._fileSizeBlock = true })
  } else if (!uploads.enabled || uploads.pending === 0) {
    if (form) form.querySelectorAll("[type=submit]").forEach(btn => {
      if (btn._fileSizeBlock) { btn.disabled = false; delete btn._fileSizeBlock }
    })
  }

  const ok = Array.from(files).filter(f => f.size <= limit)
  let labelText = ok.length + " file" + (ok.length !== 1 ? "s" : "") + " ready"
  if (oversized.length) labelText += ` · ${oversized.length} too large`
  if (uploads.enabled && uploads.pending > 0) labelText += ` · uploading ${uploads.pending}…`
  label.textContent = labelText

  if (uploads.enabled && uploads.pending > 0) {
    setUploadStatus("Uploading to storage…", "info")
  } else if (uploads.enabled && ok.length && uploads.errors.length === 0) {
    setUploadStatus("Files uploaded — ready to post.", "info")
  }

  const zone = document.getElementById("file-drop-zone")
  Array.from(files).forEach(file => {
    const tooBig = file.size > limit
    const key    = fileKey(file)
    const entry  = zone?._uploads?.get(key)
    const isImg  = file.type.startsWith("image/")
    const isVid  = file.type.startsWith("video/")
    const tag    = isImg ? "IMG" : isVid ? "VID" : "FILE"
    const row    = document.createElement("div")
    row.style.cssText = `font-size:10px;padding:3px 5px;margin-bottom:2px;display:flex;align-items:center;gap:6px;`
      + `background:${tooBig ? "rgba(192,80,80,0.08)" : "rgba(255,255,255,0.02)"};`
      + `border:1px solid ${tooBig ? "#803030" : "#2e2e2e"};border-radius:2px;`

    let statusText = fmtSize(file.size)
    if (entry?.status === "uploading") {
      statusText = `${Math.round((entry.progress || 0) * 100)}% uploaded`
    } else if (entry?.status === "done") {
      statusText = "Ready"
    } else if (entry?.status === "error") {
      statusText = "Upload failed"
    }

    row.innerHTML = `<span style="border:1px solid #555;padding:1px 4px;font-size:9px;color:${tooBig?"#e07070":"#aaa"};">${tag}</span>`
      + `<span style="flex:1;color:${tooBig?"#e07070":"#a8c8f0"};white-space:nowrap;overflow:hidden;text-overflow:ellipsis;" title="${file.name}">${file.name}</span>`
      + `<span style="color:${tooBig || entry?.status === "error" ? "#e07070" : "#555"};flex-shrink:0;">${statusText}</span>`
      + (tooBig ? `<span style="color:#e07070;font-weight:bold;flex-shrink:0;">✕ Too large</span>` : "")
    if (isImg && !tooBig && (!entry || entry.status === "done")) {
      const img = document.createElement("img")
      img.style.cssText = "height:34px;width:auto;border:1px solid #333;flex-shrink:0;"
      img.src = URL.createObjectURL(file)
      row.appendChild(img)
    }
    preview.appendChild(row)
  })
}

function fmtSize(b) {
  return b >= 1048576 ? (b/1048576).toFixed(1)+" MB" : (b/1024).toFixed(0)+" KB"
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

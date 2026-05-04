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

document.addEventListener("turbo:load", () => {
  if (window.Turbo) {
    window.Turbo.config.forms.confirm = (message) => siteConfirm(message)
    window.Turbo.config.drive.prefetch = false
  }
  initMentionAutocomplete()
  initFileUpload()
  initCategoryToggle()
  initBulkPosts()
  initQuotePost()
  initAdminUserSearch()
  initAdminThreadBulk()
})

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

/* ── File upload & drag-drop ── */
function initFileUpload() {
  const zone  = document.getElementById("file-drop-zone")
  const input = document.getElementById("file-upload-input")
  if (!zone || !input) return

  // Drop zone click → open file picker
  if (!zone._ddInit) {
    zone._ddInit = true
    zone.addEventListener("click", () => input.click())

    let dragCounter = 0
    zone.addEventListener("dragenter", (e) => {
      e.preventDefault(); e.stopPropagation()
      dragCounter++
      zone.style.borderColor = "var(--accent)"
      zone.style.background  = "rgba(61,159,175,0.07)"
    })
    zone.addEventListener("dragleave", (e) => {
      e.preventDefault(); e.stopPropagation()
      dragCounter--
      if (dragCounter <= 0) {
        dragCounter = 0
        zone.style.borderColor = "var(--border)"
        zone.style.background  = ""
      }
    })
    zone.addEventListener("dragover", (e) => { e.preventDefault(); e.stopPropagation() })
    zone.addEventListener("drop", (e) => {
      e.preventDefault(); e.stopPropagation()
      dragCounter = 0
      zone.style.borderColor = "var(--border)"
      zone.style.background  = ""
      const dropped = Array.from(e.dataTransfer.files)
      if (!dropped.length) return
      const dt = new DataTransfer()
      Array.from(input.files).forEach(f => dt.items.add(f))
      dropped.forEach(f => dt.items.add(f))
      input.files = dt.files
      processFiles(Array.from(input.files), input)
    })
  }

  input.addEventListener("change", function() { processFiles(Array.from(this.files), this) })
}

function processFiles(files, inputEl) {
  const MAX_BYTES = 100 * 1024 * 1024
  const label   = document.getElementById("file-list-label")
  const preview = document.getElementById("file-preview-list")
  const errBox  = document.getElementById("file-size-error")
  if (!label || !preview || !errBox) return

  preview.innerHTML    = ""
  errBox.style.display = "none"
  errBox.textContent   = ""
  if (!files.length) { label.textContent = ""; return }

  const oversized = files.filter(f => f.size > MAX_BYTES)
  const form = inputEl ? inputEl.closest("form") : null

  if (oversized.length) {
    errBox.style.display = "block"
    errBox.innerHTML = "<strong>File size exceeded (100 MB limit):</strong>"
      + "<ul style='margin:4px 0 0 16px; padding:0;'>"
      + oversized.map(f => "<li>" + f.name + " — " + fmtSize(f.size) + "</li>").join("")
      + "</ul>"
    if (form) form.querySelectorAll("[type=submit]").forEach(btn => { btn.disabled = true; btn._disabledByFileCheck = true })
  } else {
    if (form) form.querySelectorAll("[type=submit]").forEach(btn => {
      if (btn._disabledByFileCheck) { btn.disabled = false; btn._disabledByFileCheck = false }
    })
  }

  const ok = files.filter(f => f.size <= MAX_BYTES)
  label.textContent = ok.length + " file" + (ok.length !== 1 ? "s" : "") + " ready"
    + (oversized.length ? " · " + oversized.length + " too large" : "")

  files.forEach(file => {
    const tooBig = file.size > MAX_BYTES
    const row = document.createElement("div")
    row.style.cssText = "font-size:10px; padding:4px 6px; margin-bottom:2px; display:flex; align-items:center; gap:8px;"
      + "background:" + (tooBig ? "rgba(192,80,80,0.08)" : "rgba(255,255,255,0.02)") + ";"
      + "border:1px solid " + (tooBig ? "#803030" : "var(--border-dim,#333)") + "; border-radius:2px;"
    const color = file.type.startsWith("image/") ? "#7fd4e0" : file.type.startsWith("video/") ? "#9b8fff" : file.type.includes("pdf") ? "#f0a060" : file.type.includes("zip") ? "#80c880" : "#aaaaaa"
    const lbl   = file.type.startsWith("image/") ? "IMG" : file.type.startsWith("video/") ? "VID" : file.type.includes("pdf") ? "PDF" : file.type.includes("zip") ? "ZIP" : "FILE"
    row.innerHTML = `<span style="padding:1px 5px;font-size:9px;font-weight:bold;border-radius:2px;background:rgba(255,255,255,0.06);color:${color};">${lbl}</span>`
      + `<span style="flex:1;color:${tooBig ? "#e07070" : "var(--text-bright,#efefef)"};white-space:nowrap;overflow:hidden;text-overflow:ellipsis;" title="${file.name}">${file.name}</span>`
      + `<span style="color:${tooBig ? "#e07070" : "var(--text-muted,#666)"};flex-shrink:0;">${fmtSize(file.size)}</span>`
      + (tooBig ? `<span style="color:#e07070;font-weight:bold;flex-shrink:0;">✕ Too large</span>` : "")
    if (file.type.startsWith("image/") && !tooBig) {
      const img = document.createElement("img")
      img.style.cssText = "height:36px;width:auto;border-radius:1px;border:1px solid var(--border-dim,#333);flex-shrink:0;"
      img.src = URL.createObjectURL(file)
      row.appendChild(img)
    }
    preview.appendChild(row)
  })
}

function fmtSize(bytes) {
  return bytes >= 1048576 ? (bytes / 1048576).toFixed(1) + " MB" : (bytes / 1024).toFixed(0) + " KB"
}

/* ── Category collapse toggle ── */
function initCategoryToggle() {
  const meta = document.getElementById("category-collapsed-ids")
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
      const collapsed = body.style.display === "none"
      if (collapsed) {
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

/* ── Bulk post checkboxes ── */
function initBulkPosts() {
  const bar   = document.getElementById("bulk-delete-bar")
  const count = document.getElementById("bulk-count")
  if (!bar || !count) return
  document.addEventListener("change", function(e) {
    if (!e.target.classList.contains("bulk-check")) return
    const checked = document.querySelectorAll(".bulk-check:checked").length
    count.textContent = checked + " post" + (checked === 1 ? "" : "s") + " selected"
    bar.style.display = checked > 0 ? "flex" : "none"
  })
}

/* ── Quote post ── */
function initQuotePost() {
  document.querySelectorAll("[data-quote-post-id]").forEach(link => {
    if (link._quoteInit) return
    link._quoteInit = true
    link.addEventListener("click", (e) => {
      e.preventDefault()
      const postId = link.dataset.quotePostId
      const field   = document.getElementById("quote_post_id_field")
      const preview = document.getElementById("quote-preview")
      const form    = document.getElementById("reply-form")
      if (!field) return
      field.value = postId
      if (preview) { preview.style.display = "block"; preview.textContent = "Quoting post #" + postId }
      if (form)    form.scrollIntoView({ behavior: "smooth" })
    })
  })
}

/* ── Admin user search live filter ── */
function initAdminUserSearch() {
  const form  = document.getElementById("admin-user-search-form")
  const input = document.getElementById("admin-user-search-input")
  if (!form || !input || form._adminSearchInit) return
  form._adminSearchInit = true
  let timer
  input.addEventListener("input", () => {
    clearTimeout(timer)
    timer = setTimeout(() => form.requestSubmit(), 450)
  })
  form.querySelectorAll("select").forEach(sel => sel.addEventListener("change", () => form.requestSubmit()))
}

/* ── Admin thread bulk actions ── */
function initAdminThreadBulk() {
  const selectAll   = document.getElementById("bulk-select-all")
  const deselectAll = document.getElementById("bulk-deselect-all")
  const bulkForm    = document.getElementById("bulk-form")
  if (!bulkForm || bulkForm._bulkInit) return
  bulkForm._bulkInit = true

  if (selectAll)   selectAll.addEventListener("click",   () => document.querySelectorAll(".bulk-cb").forEach(cb => cb.checked = true))
  if (deselectAll) deselectAll.addEventListener("click", () => document.querySelectorAll(".bulk-cb").forEach(cb => cb.checked = false))

  bulkForm.querySelector("select[name='bulk_action']")?.addEventListener("change", function() {
    const mt = document.getElementById("move-target")
    if (mt) mt.style.display = this.value === "move" ? "inline-block" : "none"
  })

  bulkForm.addEventListener("submit", async function(event) {
    const action = bulkForm.querySelector("select[name='bulk_action']")?.value
    const count  = document.querySelectorAll(".bulk-cb:checked").length
    if (!action) { event.preventDefault(); await window.siteAlert("Please select an action."); return }
    if (!count)  { event.preventDefault(); await window.siteAlert("Please select at least one thread."); return }
    if (action === "delete" && !event.target.dataset.confirmed) {
      event.preventDefault()
      const ok = await window.siteConfirm("Delete " + count + " thread(s)? This cannot be undone.")
      if (ok) { event.target.dataset.confirmed = "1"; event.target.requestSubmit() }
    }
  })
}

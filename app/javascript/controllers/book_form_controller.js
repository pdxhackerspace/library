import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['photo', 'scanStatus', 'isbnList', 'isbnField', 'authorList', 'authorField', 'subjectList', 'subjectField', 'metadataStatus', 'locationId', 'locationButton', 'customLocationInput']
  static values = { scanUrl: String, lookupUrl: String, lookupToken: String }

  connect() {
    this.lookupTimer = null
    this.syncLocationButtons()
  }

  disconnect() {
    clearTimeout(this.lookupTimer)
  }

  openCamera() {
    this.photoTarget.click()
  }

  async scanPhoto() {
    const file = this.photoTarget.files[0]
    if (!file) return

    this.setScanStatus('Scanning photo…', 'secondary')
    this.photoTarget.value = ''

    const body = new FormData()
    body.append('photo', file)

    try {
      const response = await fetch(this.scanUrlValue, {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body
      })

      const data = await response.json()
      if (!response.ok) {
        this.setScanStatus(data.error || 'Could not scan photo.', 'warning')
        return
      }

      if (data.isbns?.length) {
        this.fillIsbns(data.isbns)
        this.setScanStatus(`Found ${data.isbns.length} ISBN code${data.isbns.length === 1 ? '' : 's'}.`, 'success')
        this.scheduleLookup()
      } else {
        this.setScanStatus('No ISBN barcode found in photo.', 'secondary')
      }
    } catch (_error) {
      this.setScanStatus('Could not scan photo.', 'warning')
    }
  }

  scheduleLookup() {
    clearTimeout(this.lookupTimer)
    this.lookupTimer = setTimeout(() => this.lookupMetadata(), 400)
  }

  lookupMetadata() {
    const isbn = this.primaryIsbn()
    if (!isbn || !this.lookupUrlValue || !this.lookupTokenValue) return

    this.setMetadataStatus('Looking up book info…', 'secondary', true)

    fetch(this.lookupUrlValue, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': this.csrfToken
      },
      body: (() => {
        const body = new FormData()
        body.append('isbn', isbn)
        body.append('lookup_token', this.lookupTokenValue)
        return body
      })()
    }).then((response) => {
      if (!response.ok) {
        return response.json().then((data) => {
          throw new Error(data.error || 'Lookup failed.')
        })
      }
    }).catch((error) => {
      this.setMetadataStatus(error.message, 'warning', false)
    })
  }

  addIsbnField() {
    const field = this.buildIsbnField('')
    field.querySelector('input').dataset.action = 'input->book-form#scheduleLookup blur->book-form#scheduleLookup'
    this.isbnListTarget.appendChild(field)
  }

  addAuthorField() {
    this.authorListTarget.appendChild(this.buildAuthorField(''))
  }

  removeAuthorField(event) {
    const fields = this.authorFieldTargets
    if (fields.length <= 1) {
      fields[0].querySelector('input').value = ''
      return
    }

    event.currentTarget.closest('[data-book-form-target="authorField"]').remove()
  }

  buildAuthorField(value) {
    const wrapper = document.createElement('div')
    wrapper.className = 'input-group input-group-sm mb-2'
    wrapper.dataset.bookFormTarget = 'authorField'
    wrapper.innerHTML = `
      <input type="text" name="book[author_names][]" value="${this.escapeHtml(value)}" class="form-control form-control-sm" autocomplete="off">
      <button type="button" class="btn btn-outline-secondary" data-action="book-form#removeAuthorField" aria-label="Remove author">×</button>
    `
    return wrapper
  }

  addSubjectField() {
    this.subjectListTarget.appendChild(this.buildSubjectField(''))
  }

  removeSubjectField(event) {
    const fields = this.subjectFieldTargets
    if (fields.length <= 1) {
      fields[0].querySelector('input').value = ''
      return
    }

    event.currentTarget.closest('[data-book-form-target="subjectField"]').remove()
  }

  buildSubjectField(value) {
    const wrapper = document.createElement('div')
    wrapper.className = 'input-group input-group-sm mb-2'
    wrapper.dataset.bookFormTarget = 'subjectField'
    wrapper.innerHTML = `
      <input type="text" name="book[subject_names][]" value="${this.escapeHtml(value)}" class="form-control form-control-sm" autocomplete="off">
      <button type="button" class="btn btn-outline-secondary" data-action="book-form#removeSubjectField" aria-label="Remove subject">×</button>
    `
    return wrapper
  }

  fillIsbns(isbns) {
    const fields = this.isbnFieldTargets

    isbns.forEach((code, index) => {
      let field = fields[index]
      if (!field) {
        field = this.buildIsbnField(code)
        this.isbnListTarget.appendChild(field)
      } else {
        field.querySelector('input').value = code
      }
    })
  }

  buildIsbnField(value) {
    const wrapper = document.createElement('div')
    wrapper.className = 'input-group input-group-sm mb-2'
    wrapper.dataset.bookFormTarget = 'isbnField'
    wrapper.innerHTML = `
      <input type="text" name="book[isbn_codes][]" value="${this.escapeHtml(value)}" class="form-control form-control-sm" inputmode="numeric" autocomplete="off" data-action="input->book-form#scheduleLookup blur->book-form#scheduleLookup">
      <button type="button" class="btn btn-outline-secondary" data-action="book-form#removeIsbnField" aria-label="Remove ISBN">×</button>
    `
    return wrapper
  }

  removeIsbnField(event) {
    const fields = this.isbnFieldTargets
    if (fields.length <= 1) {
      fields[0].querySelector('input').value = ''
      return
    }

    event.currentTarget.closest('[data-book-form-target="isbnField"]').remove()
  }

  setLocation(event) {
    this.locationIdTarget.value = event.currentTarget.dataset.locationId
    if (this.hasCustomLocationInputTarget) {
      this.customLocationInputTarget.value = ''
    }
    this.syncLocationButtons()
  }

  clearLocationSelection() {
    this.locationIdTarget.value = ''
    this.syncLocationButtons()
  }

  syncLocationButtons() {
    if (!this.hasLocationButtonTarget || !this.hasLocationIdTarget) return

    const selectedId = this.locationIdTarget.value
    this.locationButtonTargets.forEach((button) => {
      button.classList.toggle('active', button.dataset.locationId === selectedId)
    })
  }

  primaryIsbn() {
    return this.isbnFieldTargets
      .map((field) => field.querySelector('input').value.trim())
      .find((value) => value.length > 0)
  }

  setScanStatus(message, tone) {
    if (!this.hasScanStatusTarget) return

    this.scanStatusTarget.textContent = message
    this.scanStatusTarget.className = `small mt-2 text-${tone}`
  }

  setMetadataStatus(message, tone, loading) {
    const target = document.getElementById('metadata_lookup_status')
    if (!target) return

    target.className = `small mt-2 text-${tone}`
    target.innerHTML = loading
      ? `<span class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span>${this.escapeHtml(message)}`
      : this.escapeHtml(message)
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }

  escapeHtml(value) {
    return value
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
  }
}

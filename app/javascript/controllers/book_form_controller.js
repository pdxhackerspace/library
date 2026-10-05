import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['photo', 'preview', 'video', 'scanButton', 'stopButton', 'scanStatus', 'isbnList', 'isbnField', 'authorList', 'authorField', 'subjectList', 'subjectField', 'metadataStatus', 'nfcButton', 'locationId', 'locationButton', 'customLocationInput']
  static values = { lookupUrl: String, lookupToken: String }

  connect() {
    this.lookupTimer = null
    this.syncLocationButtons()
    this.showNfcButton()
  }

  disconnect() {
    clearTimeout(this.lookupTimer)
    this.stopCamera()
    this.terminateOcrWorker()
  }

  // Same device check as nfc_write_controller: Web NFC (Android) or the iOS Shortcuts flow.
  showNfcButton() {
    if (!this.hasNfcButtonTarget) return

    const ios = /iPad|iPhone|iPod/.test(navigator.userAgent) ||
      (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)
    if ('NDEFReader' in window || ios) this.nfcButtonTarget.classList.remove('d-none')
  }

  openCamera() {
    if (navigator.mediaDevices?.getUserMedia) {
      // Restart cleanly if a previous scan is somehow still marked active.
      this.scanSession = null
      this.stopCamera()
      this.startLiveScan()
    } else {
      this.photoTarget.click()
    }
  }

  stopScan() {
    this.scanSession = null
    this.stopCamera()
    this.setScanStatus('Scan cancelled. You can enter the ISBN manually below.', 'secondary')
  }

  async startLiveScan() {
    const session = {}
    this.scanSession = session
    this.setScanStatus('Starting camera…', 'secondary')

    try {
      await this.runLiveScan(session)
    } catch (_error) {
      if (this.scanSession === session) {
        this.scanSession = null
        this.stopCamera()
        this.giveUpScanning()
      }
    }
  }

  async runLiveScan(session) {
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' }, audio: false })
    } catch (_error) {
      if (this.scanSession !== session) return
      this.scanSession = null
      this.setScanStatus('Could not open the camera. Take a photo instead, or enter the ISBN manually below.', 'warning')
      this.photoTarget.click()
      return
    }
    if (this.scanSession !== session) return this.stopCamera()

    this.previewTarget.classList.remove('d-none')
    this.scanButtonTarget.classList.add('d-none')
    this.stopButtonTarget.classList.remove('d-none')
    this.videoTarget.srcObject = this.stream
    this.videoTarget.play().catch(() => {})

    this.setScanStatus('Loading text recognition…', 'secondary')
    const worker = await Promise.race([
      this.ocrWorker().catch(() => null),
      new Promise((resolve) => setTimeout(() => resolve(null), 15000))
    ])
    if (this.scanSession !== session) return

    this.setScanStatus('Hold the ISBN steady in view…', 'secondary')
    const isbn = await this.pollForIsbn(session, worker)
    if (this.scanSession !== session) return

    this.scanSession = null
    this.stopCamera()
    if (isbn) {
      this.applyScanResult([isbn])
    } else {
      this.giveUpScanning()
    }
  }

  // Try every 0.5s for 5s; frames are skipped while a previous attempt is still running.
  pollForIsbn(session, worker) {
    const intervalMs = 500
    const attempts = 10

    return new Promise((resolve) => {
      let tick = 0
      let busy = false
      const finish = (result) => {
        clearInterval(timer)
        resolve(result)
      }
      const timer = setInterval(async () => {
        if (this.scanSession !== session) return finish(null)
        if (tick >= attempts) return finish(null)
        tick += 1
        if (busy) return

        busy = true
        try {
          const frame = this.captureFrame()
          const isbn = frame && (await this.findIsbn(frame, worker))
          if (isbn && this.scanSession === session) finish(isbn)
        } catch (_error) {
          // ignore this frame and try the next one
        } finally {
          busy = false
        }
      }, intervalMs)
    })
  }

  captureFrame() {
    const video = this.videoTarget
    if (!video.videoWidth) return null

    const canvas = document.createElement('canvas')
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    canvas.getContext('2d').drawImage(video, 0, 0)
    return canvas
  }

  stopCamera() {
    this.stream?.getTracks().forEach((track) => track.stop())
    this.stream = null
    if (this.hasVideoTarget) this.videoTarget.srcObject = null
    if (this.hasPreviewTarget) this.previewTarget.classList.add('d-none')
    if (this.hasScanButtonTarget) this.scanButtonTarget.classList.remove('d-none')
    if (this.hasStopButtonTarget) this.stopButtonTarget.classList.add('d-none')
  }

  // OCR first (printed ISBN text), then the barcode detector.
  async findIsbn(image, worker) {
    if (worker) {
      const { data } = await worker.recognize(image)
      const isbn = this.isbnFromText(data.text)
      if (isbn) return isbn
    }

    if ('BarcodeDetector' in window) {
      const detector = new BarcodeDetector({ formats: ['ean_13'] })
      const barcodes = await detector.detect(image)
      return barcodes.map((barcode) => barcode.rawValue).find((code) => this.validIsbn13(code))
    }

    return null
  }

  async ocrWorker() {
    this.ocrWorkerPromise ||= import('tesseract.js').then(async (Tesseract) => {
      const worker = await (Tesseract.createWorker || Tesseract.default.createWorker)('eng')
      await worker.setParameters({
        tessedit_char_whitelist: '0123456789Xx-ISBN',
        tessedit_pageseg_mode: '11'
      })
      return worker
    })
    return this.ocrWorkerPromise
  }

  terminateOcrWorker() {
    this.ocrWorkerPromise?.then((worker) => worker.terminate()).catch(() => {})
    this.ocrWorkerPromise = null
  }

  isbnFromText(text) {
    const candidates = text.match(/[\dXx][\dXx -]{8,16}[\dXx]/g) || []
    for (const candidate of candidates) {
      const code = candidate.replace(/[^\dXx]/g, '').toUpperCase()
      if (this.validIsbn13(code) || this.validIsbn10(code)) return code
    }
    return null
  }

  applyScanResult(isbns) {
    this.fillIsbns(isbns)
    this.setScanStatus(`Found ${isbns.length} ISBN code${isbns.length === 1 ? '' : 's'}.`, 'success')
    this.scheduleLookup()
  }

  giveUpScanning() {
    this.setScanStatus('Could not find an ISBN. Enter it manually below.', 'warning')
    this.isbnFieldTargets[0]?.querySelector('input')?.focus()
  }

  async scanPhoto() {
    const file = this.photoTarget.files[0]
    if (!file) return

    this.photoTarget.value = ''
    this.setScanStatus('Scanning photo…', 'secondary')

    try {
      const bitmap = await createImageBitmap(file)
      const worker = await this.ocrWorker().catch(() => null)
      let isbn
      try {
        isbn = await this.findIsbn(bitmap, worker)
      } finally {
        bitmap.close()
      }

      if (isbn) {
        this.applyScanResult([isbn])
      } else {
        this.giveUpScanning()
      }
    } catch (_error) {
      this.giveUpScanning()
    }
  }

  validIsbn13(code) {
    if (!/^97[89]\d{10}$/.test(code)) return false

    const sum = [...code.slice(0, 12)].reduce((total, digit, index) => total + Number(digit) * (index % 2 === 0 ? 1 : 3), 0)
    return (10 - (sum % 10)) % 10 === Number(code[12])
  }

  validIsbn10(code) {
    if (!/^\d{9}[\dX]$/.test(code)) return false

    const sum = [...code].reduce((total, char, index) => total + (char === 'X' ? 10 : Number(char)) * (10 - index), 0)
    return sum % 11 === 0
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

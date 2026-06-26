import { Controller } from '@hotwired/stimulus'
import { buildNdefWriteRecords } from 'nfc/ndef_write_records'

export default class extends Controller {
  static targets = ['writeButton', 'status']
  static values = {
    url: String,
    json: String,
    shortcutName: String,
    jsonTruncated: Boolean
  }

  connect() {
    this.mode = this.detectMode()
    if (this.mode && this.hasWriteButtonTarget) {
      this.writeButtonTarget.classList.remove('d-none')
    }
  }

  write(event) {
    event.preventDefault()

    if (this.mode === 'webnfc') {
      this.writeAndroid()
    } else if (this.mode === 'shortcuts') {
      this.writeIos()
    }
  }

  async copyLink(event) {
    event.preventDefault()

    try {
      await navigator.clipboard.writeText(this.urlValue)
      this.setStatus('Book link copied.', 'secondary')
    } catch (_error) {
      this.setStatus('Could not copy link.', 'warning')
    }
  }

  async writeAndroid() {
    this.setStatus('Hold phone to tag…', 'secondary')

    try {
      const ndef = new NDEFReader()
      await ndef.write({ records: buildNdefWriteRecords(this.urlValue, this.jsonValue) })

      const suffix = this.jsonTruncatedValue ? ' Metadata was shortened to fit the tag.' : ''
      this.setStatus(`Tag written.${suffix}`, 'success')
    } catch (error) {
      this.setStatus(this.errorMessage(error), 'warning')
    }
  }

  writeIos() {
    const name = encodeURIComponent(this.shortcutNameValue)
    const text = encodeURIComponent(this.urlValue)
    const shortcutsUrl = `shortcuts://run-shortcut?name=${name}&input=text&text=${text}`

    this.setStatus('Opening Shortcuts — hold phone to tag when prompted.', 'secondary')
    window.location.href = shortcutsUrl
  }

  detectMode() {
    if ('NDEFReader' in window) return 'webnfc'
    if (this.iosDevice()) return 'shortcuts'

    return null
  }

  iosDevice() {
    return /iPad|iPhone|iPod/.test(navigator.userAgent) ||
      (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)
  }

  errorMessage(error) {
    const name = error?.name || ''

    if (name === 'NotAllowedError') return 'NFC permission denied.'
    if (name === 'NotSupportedError') return 'NFC is not available on this device.'
    if (name === 'NetworkError') return 'Lost contact with tag — try again.'

    return error?.message || 'Could not write tag.'
  }

  setStatus(message, tone) {
    if (!this.hasStatusTarget) return

    this.statusTarget.textContent = message
    this.statusTarget.className = `text-13 text-${tone} mt-1`
    this.statusTarget.classList.remove('d-none')
  }
}

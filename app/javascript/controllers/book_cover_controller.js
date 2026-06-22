import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['primary', 'thumb']

  select(event) {
    const url = event.params.url
    if (!url || !this.hasPrimaryTarget) return

    this.primaryTarget.src = url
    this.thumbTargets.forEach((thumb) => {
      thumb.classList.toggle('active', thumb.closest('button') === event.currentTarget)
    })
  }
}

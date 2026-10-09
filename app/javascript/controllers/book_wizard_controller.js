import { Controller } from '@hotwired/stimulus'

// Multistep book form. Every step lives in one form so ISBN lookups can fill fields on later steps.
// New books walk the steps in order; when editing, any step can be opened and saved from.
export default class extends Controller {
  static targets = ['step', 'crumb', 'backButton', 'nextButton', 'saveActions', 'authorList']
  static values = { index: Number, reached: Number, editing: Boolean }

  connect() {
    this.reachedValue = Math.max(this.reachedValue, this.indexValue)
    this.element.addEventListener('invalid', this.revealInvalid, true)
    this.render()
  }

  disconnect() {
    this.element.removeEventListener('invalid', this.revealInvalid, true)
  }

  next() {
    if (!this.validateStep(this.indexValue)) return

    this.goTo(this.indexValue + 1)
  }

  back() {
    this.goTo(this.indexValue - 1)
  }

  jump(event) {
    event.preventDefault()
    const index = Number(event.currentTarget.dataset.stepIndex)
    if (!this.canJumpTo(index)) return

    this.goTo(index)
  }

  // Enter in a text field on an earlier step of a new book advances instead of saving.
  advanceOnEnter(event) {
    if (this.editingValue || this.onLastStep) return
    if (event.target.tagName !== 'INPUT' || ['button', 'submit'].includes(event.target.type)) return

    event.preventDefault()
    this.next()
  }

  submit(event) {
    if (this.authorsPresent()) return

    event.preventDefault()
    this.goTo(this.stepIndexFor(this.authorListTarget))
    this.validateStep(this.indexValue)
  }

  clearAuthorError() {
    this.authorInputs.forEach((input) => input.setCustomValidity(''))
  }

  goTo(index) {
    if (index < 0 || index >= this.stepTargets.length) return

    this.indexValue = index
    this.reachedValue = Math.max(this.reachedValue, index)
    this.render()
    this.element.scrollIntoView({ block: 'start', behavior: 'smooth' })
  }

  canJumpTo(index) {
    return this.editingValue || index <= this.reachedValue
  }

  render() {
    this.stepTargets.forEach((step, index) => step.classList.toggle('d-none', index !== this.indexValue))

    this.crumbTargets.forEach((crumb, index) => {
      const current = index === this.indexValue
      const link = crumb.querySelector('a')
      const label = crumb.querySelector('span')
      const linked = !current && this.canJumpTo(index)

      crumb.classList.toggle('fw-semibold', current)
      label.classList.toggle('text-body', current)
      label.classList.toggle('text-secondary', !current)
      if (current) {
        crumb.setAttribute('aria-current', 'step')
      } else {
        crumb.removeAttribute('aria-current')
      }
      link.classList.toggle('d-none', !linked)
      label.classList.toggle('d-none', linked)
    })

    this.backButtonTarget.classList.toggle('d-none', this.indexValue === 0)
    this.nextButtonTarget.classList.toggle('d-none', this.onLastStep)
    this.saveActionsTarget.classList.toggle('d-none', !(this.editingValue || this.onLastStep))
  }

  validateStep(index) {
    const step = this.stepTargets[index]
    const fields = [...step.querySelectorAll('input, textarea, select')].filter((field) => field.willValidate)

    if (step.contains(this.authorListTarget)) {
      const first = this.authorInputs[0]
      first?.setCustomValidity(this.authorsPresent() ? '' : 'Enter at least one author.')
    }

    const invalid = fields.find((field) => !field.checkValidity())
    if (!invalid) return true

    invalid.reportValidity()
    return false
  }

  authorsPresent() {
    return this.authorInputs.some((input) => input.value.trim().length > 0)
  }

  get authorInputs() {
    return [...this.authorListTarget.querySelectorAll('input')]
  }

  get onLastStep() {
    return this.indexValue === this.stepTargets.length - 1
  }

  stepIndexFor(element) {
    return this.stepTargets.findIndex((step) => step.contains(element))
  }

  // Browser validation on save can trip over a field on a hidden step; show that step first.
  revealInvalid = (event) => {
    const index = this.stepIndexFor(event.target)
    if (index < 0 || index === this.indexValue) return

    this.indexValue = index
    this.reachedValue = Math.max(this.reachedValue, index)
    this.render()
  }
}

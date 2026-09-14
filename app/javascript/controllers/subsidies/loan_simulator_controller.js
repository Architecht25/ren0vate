import { Controller } from "@hotwired/stimulus"

// Loan simulator controller
// Handles all loan types: classic (with rate) and 0% loans (verbouwlening, renopack, ecoreno)
export default class extends Controller {
  static targets = [
    "amount", "amountDisplay",
    "duration", "durationDisplay",
    "rate", "rateDisplay",
    "categorySelect",
    "monthlyPayment", "totalCost", "totalInterest",
    "resultSection",
    "amortizationBody",
    "rateBlock",
    "saveForm", "saveLabel", "saveAmount", "saveRate", "saveDuration", "saveNotes"
  ]

  static values = { loanTypeLabel: String }

  connect() {
    this.calculate()
  }

  // Called when any input changes
  update() {
    this.syncDisplays()
    this.calculate()
  }

  // Sync range slider values to display spans
  syncDisplays() {
    if (this.hasAmountDisplayTarget && this.hasAmountTarget) {
      this.amountDisplayTarget.textContent = this.formatCurrency(parseFloat(this.amountTarget.value))
    }
    if (this.hasDurationDisplayTarget && this.hasDurationTarget) {
      const years = parseInt(this.durationTarget.value)
      this.durationDisplayTarget.textContent = `${years} an${years > 1 ? 's' : ''}`
    }
    if (this.hasRateDisplayTarget && this.hasRateTarget) {
      this.rateDisplayTarget.textContent = `${parseFloat(this.rateTarget.value).toFixed(2)}%`
    }
  }

  // When income category changes (verbouwlening), update rate
  updateCategory() {
    if (!this.hasCategorySelectTarget) return
    const selected = this.categorySelectTarget.selectedOptions[0]
    const rate = selected?.dataset?.rate || "0"
    if (this.hasRateTarget) {
      this.rateTarget.value = rate
      if (this.hasRateDisplayTarget) {
        this.rateDisplayTarget.textContent = `${parseFloat(rate).toFixed(2)}%`
      }
    }
    this.calculate()
  }

  calculate() {
    if (!this.hasAmountTarget || !this.hasDurationTarget) return

    const amount = parseFloat(this.amountTarget.value) || 0
    const durationYears = parseInt(this.durationTarget.value) || 0
    const n = durationYears * 12 // total months
    const annualRate = this.hasRateTarget ? (parseFloat(this.rateTarget.value) || 0) : 0
    const r = annualRate / 100 / 12 // monthly rate

    if (amount <= 0 || n <= 0) {
      if (this.hasResultSectionTarget) this.resultSectionTarget.classList.add("d-none")
      return
    }

    let monthly
    if (r === 0) {
      monthly = amount / n
    } else {
      monthly = amount * r * Math.pow(1 + r, n) / (Math.pow(1 + r, n) - 1)
    }

    const totalCost = monthly * n
    const totalInterest = totalCost - amount

    if (this.hasMonthlyPaymentTarget) {
      this.monthlyPaymentTarget.textContent = this.formatCurrency(monthly)
    }
    if (this.hasTotalCostTarget) {
      this.totalCostTarget.textContent = this.formatCurrency(totalCost)
    }
    if (this.hasTotalInterestTarget) {
      this.totalInterestTarget.textContent = this.formatCurrency(totalInterest)
    }

    if (this.hasResultSectionTarget) {
      this.resultSectionTarget.classList.remove("d-none")
    }

    this.buildAmortizationTable(amount, r, monthly, n)
  }

  buildAmortizationTable(principal, r, monthly, totalMonths) {
    if (!this.hasAmortizationBodyTarget) return

    let balance = principal
    let rows = ""

    for (let year = 1; year <= Math.ceil(totalMonths / 12); year++) {
      const monthsInYear = Math.min(12, totalMonths - (year - 1) * 12)
      let yearInterest = 0
      let yearPrincipal = 0

      for (let m = 0; m < monthsInYear; m++) {
        const interestPmt = balance * r
        const principalPmt = Math.min(monthly - interestPmt, balance)
        yearInterest += interestPmt
        yearPrincipal += principalPmt
        balance = Math.max(0, balance - principalPmt)
      }

      const yearlyPaid = (year === Math.ceil(totalMonths / 12) && totalMonths % 12 !== 0)
        ? monthsInYear * monthly
        : 12 * monthly

      rows += `<tr>
        <td class="fw-semibold">Année ${year}</td>
        <td class="fw-semibold" style="color:var(--ren0vate-accent);">${this.formatCurrency(monthly)}</td>
        <td>${this.formatCurrency(yearlyPaid)}</td>
        <td>${this.formatCurrency(yearPrincipal)}</td>
        <td class="${r > 0 ? 'text-danger' : 'text-muted'}">${this.formatCurrency(yearInterest)}</td>
        <td class="fw-semibold">${this.formatCurrency(balance)}</td>
      </tr>`
    }

    this.amortizationBodyTarget.innerHTML = rows
  }

  // Pousse le résultat calculé (capital emprunté, pas le coût total avec intérêts —
  // c'est bien le capital qui finance le chantier) comme FinancingSource du projet.
  saveAsFinancingSource() {
    if (!this.hasSaveFormTarget || !this.hasAmountTarget || !this.hasDurationTarget) return

    const amount = parseFloat(this.amountTarget.value) || 0
    const rate = this.hasRateTarget ? parseFloat(this.rateTarget.value) || 0 : 0
    const years = parseInt(this.durationTarget.value) || 0
    const label = this.loanTypeLabelValue || "Prêt"

    this.saveLabelTarget.value = `${label} — ${this.formatCurrency(amount)} / ${years} an${years > 1 ? "s" : ""}`
    this.saveAmountTarget.value = amount
    this.saveRateTarget.value = rate
    this.saveDurationTarget.value = years * 12
    this.saveNotesTarget.value = `Mensualité ${this.monthlyPaymentTarget.textContent}, coût total ${this.totalCostTarget.textContent}`

    this.saveFormTarget.requestSubmit()
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("fr-BE", {
      style: "currency",
      currency: "EUR",
      maximumFractionDigits: 0
    }).format(value)
  }
}

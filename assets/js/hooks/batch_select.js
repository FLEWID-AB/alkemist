// Select-all checkbox and enabling of the batch-actions menu. Submission itself is plain
// HTML: row checkboxes carry form="batch-action-form" and each action is a submit button.
export const AlkemistBatchSelect = {
  mounted() {
    const all = this.el.querySelector("[data-batch-select-all]")
    const boxes = () => Array.from(this.el.querySelectorAll("[data-batch-select]"))
    const menu = document.getElementById(this.el.dataset.batchMenu || "batch-actions")
    const sync = () => {
      const checked = boxes().filter((b) => b.checked).length
      if (menu) menu.toggleAttribute("data-disabled", checked === 0)
      if (menu) menu.querySelectorAll("button").forEach((b) => (b.disabled = checked === 0))
      if (all) {
        all.checked = checked > 0 && checked === boxes().length
        all.indeterminate = checked > 0 && checked < boxes().length
      }
    }
    all?.addEventListener("change", () => { boxes().forEach((b) => (b.checked = all.checked)); sync() })
    this.el.addEventListener("change", (e) => { if (e.target.matches("[data-batch-select]")) sync() })
    sync()
  },
}

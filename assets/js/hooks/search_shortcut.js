// Pressing "/" anywhere outside a text field focuses the index search box.
export const AlkemistSearchShortcut = {
  mounted() {
    this.handler = (event) => {
      if (event.key !== "/" || event.metaKey || event.ctrlKey || event.altKey) return
      const target = event.target
      if (target.closest("input, textarea, select, [contenteditable]")) return
      const input = this.el.querySelector("[data-search-input]")
      if (!input) return
      event.preventDefault()
      input.focus()
      input.select()
    }
    document.addEventListener("keydown", this.handler)
  },
  destroyed() {
    document.removeEventListener("keydown", this.handler)
  },
}

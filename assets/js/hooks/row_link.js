// Makes a table row navigable by click while keeping the real link in the first cell
// for keyboard and assistive technology. Clicks on interactive children are ignored.
export const AlkemistRowLink = {
  mounted() {
    this.el.addEventListener("click", (event) => {
      if (event.defaultPrevented) return
      if (event.target.closest("a, button, input, label, select, textarea, details")) return
      const href = this.el.dataset.href
      if (!href) return
      if (event.metaKey || event.ctrlKey) window.open(href, "_blank")
      else window.location.assign(href)
    })
  },
}

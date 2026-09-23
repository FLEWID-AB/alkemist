// Navigates when the per-page <select> changes; a <noscript> fallback renders links.
export const AlkemistPerPage = {
  mounted() {
    this.el.addEventListener("change", () => {
      const url = new URL(window.location.href)
      url.searchParams.set("per_page", this.el.value)
      url.searchParams.delete("page")
      window.location.assign(url.toString())
    })
  },
}

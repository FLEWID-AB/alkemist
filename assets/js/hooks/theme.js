// Optional light/dark override persisted in localStorage. Without a stored choice the
// stylesheet follows prefers-color-scheme.
const KEY = "alkemist:theme"
export const AlkemistTheme = {
  mounted() {
    const apply = (value) => {
      document.documentElement.classList.remove("light", "dark")
      if (value) document.documentElement.classList.add(value)
    }
    try { apply(localStorage.getItem(KEY)) } catch (_e) {}
    this.el.addEventListener("click", () => {
      const current = document.documentElement.classList.contains("dark") ? "dark" : "light"
      const next = current === "dark" ? "light" : "dark"
      apply(next)
      try { localStorage.setItem(KEY, next) } catch (_e) {}
    })
  },
}

// Adds nested form groups by cloning the server-rendered <template>, replacing the
// __INDEX__ placeholder with a unique index. Removal is server-side via the drop checkbox;
// this hook only hides the group visually once it is marked for removal.
export const AlkemistNestedForm = {
  mounted() {
    const groups = this.el.querySelector("[data-nested-groups]")
    const template = this.el.querySelector("template[data-nested-template]")
    const placeholder = this.el.dataset.indexPlaceholder || "__INDEX__"
    this.el.querySelector("[data-nested-add]")?.addEventListener("click", () => {
      if (!template || !groups) return
      const html = template.innerHTML.replaceAll(placeholder, String(Date.now()))
      groups.insertAdjacentHTML("beforeend", html)
      this.el.dispatchEvent(new CustomEvent("alkemist:nested-added", { bubbles: true }))
    })
    this.el.addEventListener("change", (e) => {
      if (!e.target.matches("[data-nested-drop]")) return
      e.target.closest("[data-nested-group]")?.toggleAttribute("data-dropped", e.target.checked)
    })
  },
}

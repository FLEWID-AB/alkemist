// Page-wide behaviour for <details> dropdowns and toasts: one open dropdown at a time,
// close on outside click and Escape, and dismissible toasts. Installed once by mount().
export function installDropdowns(root = document) {
  if (root.__alkemistDropdowns) return
  root.__alkemistDropdowns = true
  const openDropdowns = () => root.querySelectorAll("details.ak-dropdown[open]")

  root.addEventListener("click", (event) => {
    const dismiss = event.target.closest("[data-dismiss-toast]")
    if (dismiss) dismiss.closest(".ak-toast")?.remove()
    const inside = event.target.closest("details.ak-dropdown")
    openDropdowns().forEach((d) => { if (d !== inside) d.removeAttribute("open") })
  })

  root.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return
    openDropdowns().forEach((d) => {
      d.removeAttribute("open")
      d.querySelector("summary")?.focus()
    })
  })
}

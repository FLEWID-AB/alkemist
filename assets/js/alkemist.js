// Prebuilt bundle entry (mode A). Imports phoenix_html for data-method/data-confirm links,
// exposes the hooks for LiveView (`new LiveSocket(..., {hooks: {...AlkemistHooks}})`) and
// mounts them on plain pages by emulating phx-hook.
//
// Mode B hosts import { AlkemistHooks, mount } from "../../deps/alkemist/assets/js/hooks"
// style paths and must not also load this bundle (phoenix_html would be loaded twice).
import "phoenix_html"
import * as exported from "./hooks/index.js"

const { installDropdowns, ...hooks } = exported
export const AlkemistHooks = hooks
export { installDropdowns }

export function mount(root = document) {
  installDropdowns(document)
  root.querySelectorAll("[phx-hook^='Alkemist']").forEach((el) => {
    if (el.__alkemistHook) return
    const definition = hooks[el.getAttribute("phx-hook")]
    if (!definition) return
    const hook = Object.create(definition)
    hook.el = el
    el.__alkemistHook = hook
    hook.mounted?.()
  })
}

if (typeof window !== "undefined" && !window.__alkemistMounted) {
  window.__alkemistMounted = true
  window.AlkemistHooks = AlkemistHooks
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", () => mount())
  else mount()
}

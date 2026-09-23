var __defProp = Object.defineProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};

// ../deps/phoenix_html/priv/static/phoenix_html.js
(function() {
  var PolyfillEvent = eventConstructor();
  function eventConstructor() {
    if (typeof window.CustomEvent === "function") return window.CustomEvent;
    function CustomEvent2(event, params) {
      params = params || { bubbles: false, cancelable: false, detail: void 0 };
      var evt = document.createEvent("CustomEvent");
      evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail);
      return evt;
    }
    CustomEvent2.prototype = window.Event.prototype;
    return CustomEvent2;
  }
  function buildHiddenInput(name, value) {
    var input = document.createElement("input");
    input.type = "hidden";
    input.name = name;
    input.value = value;
    return input;
  }
  function handleClick(element, targetModifierKey) {
    var to = element.getAttribute("data-to"), method = buildHiddenInput("_method", element.getAttribute("data-method")), csrf = buildHiddenInput("_csrf_token", element.getAttribute("data-csrf")), form = document.createElement("form"), submit = document.createElement("input"), target = element.getAttribute("target");
    form.method = element.getAttribute("data-method") === "get" ? "get" : "post";
    form.action = to;
    form.style.display = "none";
    if (target) form.target = target;
    else if (targetModifierKey) form.target = "_blank";
    form.appendChild(csrf);
    form.appendChild(method);
    document.body.appendChild(form);
    submit.type = "submit";
    form.appendChild(submit);
    submit.click();
  }
  window.addEventListener("click", function(e) {
    var element = e.target;
    if (e.defaultPrevented) return;
    while (element && element.getAttribute) {
      var phoenixLinkEvent = new PolyfillEvent("phoenix.link.click", {
        "bubbles": true,
        "cancelable": true
      });
      if (!element.dispatchEvent(phoenixLinkEvent)) {
        e.preventDefault();
        e.stopImmediatePropagation();
        return false;
      }
      if (element.getAttribute("data-method") && element.getAttribute("data-to")) {
        handleClick(element, e.metaKey || e.shiftKey);
        e.preventDefault();
        return false;
      } else {
        element = element.parentNode;
      }
    }
  }, false);
  window.addEventListener("phoenix.link.click", function(e) {
    var message = e.target.getAttribute("data-confirm");
    if (message && !window.confirm(message)) {
      e.preventDefault();
    }
  }, false);
})();

// js/hooks/index.js
var hooks_exports = {};
__export(hooks_exports, {
  AlkemistBatchSelect: () => AlkemistBatchSelect,
  AlkemistNestedForm: () => AlkemistNestedForm,
  AlkemistPerPage: () => AlkemistPerPage,
  AlkemistRowLink: () => AlkemistRowLink,
  AlkemistSearchShortcut: () => AlkemistSearchShortcut,
  AlkemistTheme: () => AlkemistTheme,
  installDropdowns: () => installDropdowns
});

// js/hooks/row_link.js
var AlkemistRowLink = {
  mounted() {
    this.el.addEventListener("click", (event) => {
      if (event.defaultPrevented) return;
      if (event.target.closest("a, button, input, label, select, textarea, details")) return;
      const href = this.el.dataset.href;
      if (!href) return;
      if (event.metaKey || event.ctrlKey) window.open(href, "_blank");
      else window.location.assign(href);
    });
  }
};

// js/hooks/batch_select.js
var AlkemistBatchSelect = {
  mounted() {
    const all = this.el.querySelector("[data-batch-select-all]");
    const boxes = () => Array.from(this.el.querySelectorAll("[data-batch-select]"));
    const menu = document.getElementById(this.el.dataset.batchMenu || "batch-actions");
    const sync = () => {
      const checked = boxes().filter((b) => b.checked).length;
      if (menu) menu.toggleAttribute("data-disabled", checked === 0);
      if (menu) menu.querySelectorAll("button").forEach((b) => b.disabled = checked === 0);
      if (all) {
        all.checked = checked > 0 && checked === boxes().length;
        all.indeterminate = checked > 0 && checked < boxes().length;
      }
    };
    all?.addEventListener("change", () => {
      boxes().forEach((b) => b.checked = all.checked);
      sync();
    });
    this.el.addEventListener("change", (e) => {
      if (e.target.matches("[data-batch-select]")) sync();
    });
    sync();
  }
};

// js/hooks/search_shortcut.js
var AlkemistSearchShortcut = {
  mounted() {
    this.handler = (event) => {
      if (event.key !== "/" || event.metaKey || event.ctrlKey || event.altKey) return;
      const target = event.target;
      if (target.closest("input, textarea, select, [contenteditable]")) return;
      const input = this.el.querySelector("[data-search-input]");
      if (!input) return;
      event.preventDefault();
      input.focus();
      input.select();
    };
    document.addEventListener("keydown", this.handler);
  },
  destroyed() {
    document.removeEventListener("keydown", this.handler);
  }
};

// js/hooks/nested_form.js
var AlkemistNestedForm = {
  mounted() {
    const groups = this.el.querySelector("[data-nested-groups]");
    const template = this.el.querySelector("template[data-nested-template]");
    const placeholder = this.el.dataset.indexPlaceholder || "__INDEX__";
    this.el.querySelector("[data-nested-add]")?.addEventListener("click", () => {
      if (!template || !groups) return;
      const html = template.innerHTML.replaceAll(placeholder, String(Date.now()));
      groups.insertAdjacentHTML("beforeend", html);
      this.el.dispatchEvent(new CustomEvent("alkemist:nested-added", { bubbles: true }));
    });
    this.el.addEventListener("change", (e) => {
      if (!e.target.matches("[data-nested-drop]")) return;
      e.target.closest("[data-nested-group]")?.toggleAttribute("data-dropped", e.target.checked);
    });
  }
};

// js/hooks/per_page.js
var AlkemistPerPage = {
  mounted() {
    this.el.addEventListener("change", () => {
      const url = new URL(window.location.href);
      url.searchParams.set("per_page", this.el.value);
      url.searchParams.delete("page");
      window.location.assign(url.toString());
    });
  }
};

// js/hooks/theme.js
var KEY = "alkemist:theme";
var AlkemistTheme = {
  mounted() {
    const apply = (value) => {
      document.documentElement.classList.remove("light", "dark");
      if (value) document.documentElement.classList.add(value);
    };
    try {
      apply(localStorage.getItem(KEY));
    } catch (_e) {
    }
    this.el.addEventListener("click", () => {
      const current = document.documentElement.classList.contains("dark") ? "dark" : "light";
      const next = current === "dark" ? "light" : "dark";
      apply(next);
      try {
        localStorage.setItem(KEY, next);
      } catch (_e) {
      }
    });
  }
};

// js/hooks/dropdowns.js
function installDropdowns(root = document) {
  if (root.__alkemistDropdowns) return;
  root.__alkemistDropdowns = true;
  const openDropdowns = () => root.querySelectorAll("details.ak-dropdown[open]");
  root.addEventListener("click", (event) => {
    const dismiss = event.target.closest("[data-dismiss-toast]");
    if (dismiss) dismiss.closest(".ak-toast")?.remove();
    const inside = event.target.closest("details.ak-dropdown");
    openDropdowns().forEach((d) => {
      if (d !== inside) d.removeAttribute("open");
    });
  });
  root.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return;
    openDropdowns().forEach((d) => {
      d.removeAttribute("open");
      d.querySelector("summary")?.focus();
    });
  });
}

// js/alkemist.js
var { installDropdowns: installDropdowns2, ...hooks } = hooks_exports;
var AlkemistHooks = hooks;
function mount(root = document) {
  installDropdowns2(document);
  root.querySelectorAll("[phx-hook^='Alkemist']").forEach((el) => {
    if (el.__alkemistHook) return;
    const definition = hooks[el.getAttribute("phx-hook")];
    if (!definition) return;
    const hook = Object.create(definition);
    hook.el = el;
    el.__alkemistHook = hook;
    hook.mounted?.();
  });
}
if (typeof window !== "undefined" && !window.__alkemistMounted) {
  window.__alkemistMounted = true;
  window.AlkemistHooks = AlkemistHooks;
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", () => mount());
  else mount();
}
export {
  AlkemistHooks,
  installDropdowns2 as installDropdowns,
  mount
};

exports.config = {
  files: {
    javascripts: {
      joinTo: "js/alkemist.js"
    },
    stylesheets: {
      joinTo: "css/alkemist.css"
    },
    templates: {
      joinTo: "js/alkemist.js"
    }
  },

  conventions: {
    assets: /^(static)/
  },

  paths: {
    watched: ["static", "css", "js"],
    public: "../priv/static"
  },

  plugins: {
    sass: {
      native: true,
      options: {
        includePaths: ["node_modules/bootstrap/scss", "node_modules/@coreui/coreui/scss", "node_modules/@fortawesome/fontawesome-free/scss", "node_modules/@chenfengyuan/datepicker/dist", "node_modules/alkemist-default-theme/scss"],
        precision: 8
      }
    },
    copycat: {
      "fonts": ["node_modules/@fortawesome/fontawesome-free/webfonts"],
      verbose: false,
      onlyChanged: true
    }
  },

  modules: {
    autoRequire: {
      "js/alkemist.js": ["js/alkemist"]
    }
  },

  npm: {
    enabled: true,
    globals: {
      $: 'jquery',
      jQuery: 'jquery',
      Popper: 'popper.js',
      bootstrap: 'bootstrap'
    }
  }
}

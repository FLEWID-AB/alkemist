const fs = require('fs');
const { promisify } = require('util');

const close = promisify(fs.close);
const open = promisify(fs.open);

const touch = filename => open(filename, 'wx').then(close);




exports.config = {
  hooks: {
    onCompile(generatedFiles, changedAssets) {
      if (generatedFiles.map(f => f.path).length == 0){
        fs.readFile('css/app.scss', 'utf8', function(err, content){
          fs.writeFile('css/app.scss', content, function (err){
            if (err) throw err;
            console.log("Touched app scss")
          })
        })
      }
    }
  },
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
    watched: ["static", "css", "js", "node_modules/alkemist-default-theme/scss"],
    public: "../priv/static"
  },

  plugins: {
    sass: {
      native: true,
      options: {
        includePaths: ["node_modules/bootstrap/scss", "node_modules/@coreui/coreui/scss", "node_modules/@fortawesome/fontawesome-free/scss", "node_modules/@chenfengyuan/datepicker/src/css", "node_modules/alkemist-default-theme/scss"],
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

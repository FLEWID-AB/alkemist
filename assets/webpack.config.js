const path = require('path');

module.exports = {
  mode: 'production',
  entry: {
    app: ['./js/app.js'],
  },
  output: {
    filename: 'alkemist.js',
    path: path.resolve(__dirname, '../priv/static/js')
  },
  module: {
    rules: [
      {
        test: /\.m?js$/,
        exclude: /(node_modules|bower_components)/,
        use: {
          loader: 'source-map-loader'
        },
        enforce: 'pre'
      },
      {
        test: /\.m?js$/,
        exclude: /(node_modules|bower_components)/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env']
          }
        }
      }
    ]
  },
  resolve: {
    extensions: ['.js', '.jsx', '.ts', '.tsx', '.json', '.css'],
    modules: ['src', 'node_modules'], // Assuming that your files are inside the src dir
    fallback: {
      "fs": false,
      "path": require.resolve("path-browserify")
    }
  }
}

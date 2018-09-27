export default {
  init () {
    this.$containers = $('.alkemist_hm--container')
    if (this.$containers.length > 0) {
      this.bindListeners()
    }
  },

  bindListeners () {
    this.$containers.on('click', '.alkemist_hm--add', function(e) {
      e.preventDefault()
      let $container = $(e.target).parents('.alkemist_hm--container')
      let index = $container.children('.alkemist_hm--group').length
      let template = $container.attr('data-template').replace(/\$index/g, index)
      $container.find('.alkemist_hm--groups').append(template.replace('$index', index))
    }).on('click', '.alkemist_hm--group .close', function(e) {
      e.preventDefault()
      let $container = $(e.target).parents('.alkemist_hm--group')
      $container.remove()
    })
  }
}
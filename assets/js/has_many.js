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
      let $groups = $container.children('.alkemist_hm--group')
      let index = $groups.length
      let template = $container.attr('data-template').replace(/\$index/g, index)
      console.log(template)
      $groups.after(template.replace('$index', index))
    })
  }
}
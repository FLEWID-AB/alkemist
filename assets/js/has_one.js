export default {
  init () {
    this.bindListeners()
  },

  bindListeners () {
    $('body').on('click', '.alkemist_ho--add', (e) => {
      e.preventDefault()
      let $container = $(e.target).parents('.alkemist_ho--container')
      let template = $container.attr('data-template')
      $container.find('.alkemist_ho--groups').append(template)
      this.showOrHideAdd($container)
    })
    $('body').on('click', '.alkemist_ho--group .close', (e) => {
      e.preventDefault()
      let $container = $(e.target).parents('.alkemist_ho--container')
      let $group = $(e.target).parents('.alkemist_ho--group')
      $group.remove()
      this.showOrHideAdd($container)
    })
  },

  showOrHideAdd ($container) {
    let $button = $container.find('.alkemist_ho--add')
    console.log($button)
    if ($container.find('.alkemist_ho--group').length > 0) {
      $button.hide()
    } else {
      $button.show()
    }
  }
}
export default {
  init () {
    this.bindListeners()
  },

  bindListeners () {
    $('body').on('click', '.alkemist_hm--add', (e) => {
      e.preventDefault()
      let $container = $(e.target).parents('.alkemist_hm--container')
      let $last = $container.find('.alkemist_hm--group').last()
      let index = $last.length > 0 ? parseInt($last.find(':input').first().attr('name').match(/\[([\d]+)\]/)[1]) + 1 : 0
      let template = $($container.attr('data-template').replace(/\$index/g, index))
      $container.find('.alkemist_hm--groups').append(template)
      $container.trigger('group:add', template)
    }).on('click', '.alkemist_hm--group .close', (e) => {
      e.preventDefault()
      let $container = $(e.target).parents('.alkemist_hm--container')
      let $group = $(e.target).parents('.alkemist_hm--group')
      $group.trigger('remove')
      $group.remove()
      $container.trigger('group:remove')
    })
  }
}
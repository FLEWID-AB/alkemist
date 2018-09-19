export default {
  init () {
    if (document.getElementById("more-filters")) {
      this.$filters = $('.hidden-filter')
      this.$toggle = $('#more-filters')
      this.bindListeners()
      this.checkFormState()
    }
  },

  bindListeners() {
    this.$toggle.on('click', (e) => {
      e.preventDefault()
      if (this.$toggle.hasClass('open')) {
        this.closeFilters()
      } else {
        this.openFilters()
      }
    })
  },

  openFilters() {
    this.$filters.removeClass('hide')
    this.$toggle.addClass('open').text('Less filters -')
  },

  closeFilters() {
    this.$filters.addClass('hide')
    this.$toggle.removeClass('open').text('More filters +')
  },

  checkFormState() {    
    let elements = this.$filters.find(':input')
    let shouldShow = elements.filter(function(index, elem) {
      return $(elem).val()
    }).length > 0
    
    if (shouldShow) {
      this.openFilters()
    }
  }
}
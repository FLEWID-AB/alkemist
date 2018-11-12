import EqualWidth from "./equalWidth";

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
    this.$toggle.closest('form.form').addClass('mb-4');
    this.$toggle.parent('.col-md-4').removeClass('col-md-4').addClass('col-md-12 text-right mt-2')
    EqualWidth.resizeElements(true)
  },

  closeFilters() {
    this.$filters.addClass('hide')
    this.$toggle.closest('form.form').removeClass('mb-4');
    this.$toggle.removeClass('open').text('More filters +')
    this.$toggle.parent('.col-md-12').removeClass('col-md-12 text-right mt-2').addClass('col-md-4')
    EqualWidth.resizeElements(true)
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

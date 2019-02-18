export default {
  init() {
    this.$toggler = $('#selection-toggle-all')
    this.$batchToggler = $('#batch-menu-toggler')
    this.$inputs = $('input.collection-selection')
    this.$actions = $('.batch-action-item')
    this.$batchForm = $('#batch-action-form')
    this.toggleBatchAvailability()
    this.bindListeners()
  },

  bindListeners() {
    this.$toggler.on('change', () => {
      this.$inputs.prop('checked', this.$toggler.is(':checked'))
      this.toggleBatchAvailability()
    })
    this.$inputs.on('change', () => { this.toggleBatchAvailability() })
    this.$actions.on('click', (e) => {
      e.preventDefault()
      let $link = $(e.target)
      let conf = $link.attr('data-confirm')
      let values = []
      this.$inputs.each(function (index, input) {
        let $input = $(input)
        if ($input.is(':checked')) {
          values.push($input.val())
        }
      })

      if (!conf || confirm(conf)) {
        this.$batchForm.attr('action', $link.attr('data-action'))
        this.$batchForm.find('.batch-id').remove()
        for (let i = 0, value; value = values[i]; i++) {
          this.$batchForm.append('<input type="hidden" name="batch_ids[]" value="' + value + '" class="batch-id">')
        }
        this.$batchForm.submit()
      }
    })
  },

  toggleBatchAvailability() {
    let any = this.$inputs.is(':checked')
    if (any == true) {
      this.$batchToggler.removeClass('disabled')
    } else {
      this.$batchToggler.addClass('disabled')
    }
  }
}
// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "@coreui/coreui"
import "@chenfengyuan/datepicker"
import select2 from "select2"
import HasMany from './has_many'
import Batch from './batch'
import Filter from './filter'

select2($)

$(document).ready(function () {
  $.fn.datepicker.setDefaults({
    format: 'YYYY-mm-dd'
  })
  $('select.select2').select2()
  $('input.datepicker').datepicker()
  Filter.init()
  HasMany.init()
  document.getElementById('selection-toggle-all') && Batch.init()
});
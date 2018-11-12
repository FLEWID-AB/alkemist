// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "@coreui/coreui"
import "@chenfengyuan/datepicker"
import HasMany    from './has_many'
import HasOne     from './has_one'
import Batch      from './batch'
import Filter     from './filter'
import EqualWidth from "./equalWidth";


$(document).ready(function () {
  $.fn.datepicker.setDefaults({
    format: 'YYYY-mm-dd'
  })
  $('input.datepicker').datepicker()
  Filter.init()
  HasMany.init()
  HasOne.init()
  document.getElementById('selection-toggle-all') && Batch.init()
  makeRowClickable();
  EqualWidth.init();
});

function makeRowClickable() {
  let $clickableRows = $('.clickable-row');
  $clickableRows.children('td').not('.member-actions').on('click', function() {
    window.location = $(this).parent().attr('data-href');
  })
}

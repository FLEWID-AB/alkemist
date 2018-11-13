export default {
  init(resize) {
    this.resizeElements(true)
  },
  resizeElements(resize) {
    var elements = document.getElementsByClassName("equalWidth"),
      allWidths = [],
      i = 0;
    if (resize === true) {
      for (i = 0; i < elements.length; i++) {
        elements[i].style.width = 'auto';
      }
    }
    for (i = 0; i < elements.length; i++) {
      var elementWidth = elements[i].clientWidth;
      allWidths.push(elementWidth);
    }
    for (i = 0; i < elements.length; i++) {
      elements[i].style.width = Math.max.apply(Math, allWidths) + 'px';
    }
  }
}

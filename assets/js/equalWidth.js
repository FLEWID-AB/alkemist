export default {
  init(resize) {
    this.resizeElements(true)
    // window.onresize = function(){
    //   equalWidth.resizeElements(true);
    // }
  },
  resizeElements(resize) {
    console.log("RESIZE?!?!!")
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

    console.log(allWidths);
    console.log(Math.max.apply(Math, allWidths));

    for (i = 0; i < elements.length; i++) {
      elements[i].style.width = Math.max.apply(Math, allWidths) + 'px';
      // Optional: Add show class to prevent FOUC
      // if (resize === false) {
      //   elements[i].className = elements[i].className + " show";
      // } else {

      // }
    }
  }
}

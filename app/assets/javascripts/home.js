//= require prototype
//= require modernizr
//= require s2

document.observe("dom:loaded", function() {
  slideshow  = new Slideshow(4,0.6);
});

Slideshow = Class.create({
  initialize: function(pause,speed) {
    this.pauseDuration = pause *1000;
    this.speed = speed;
    this.slideShowWrapper = $$('body.home ul.slides')[0];
    
    this.slideNames = [];
    $$('body.home .slides li').each(function(element){
      if (!element.hasClassName('active')) element.setOpacity(0);
      this.slideNames.push(this.getBoxName(element));
    }.bind(this));
    
    this.activeBoxIndex = 0;
    this.startTimer();
    this.setupObservers();
  },
  getBoxName: function(element) {
    return element.className.gsub(/(box|active|\s)/, '');
  },
  startTimer: function() {
    this.timer = setInterval(function(){
      this.nextSlide((this.activeBoxIndex+1)%(this.slideNames.length));
    }.bind(this), this.pauseDuration);
  },
  nextSlide: function(index) {
    if (this.activeBoxIndex != index) {
      var currentBox = $$('.slides li.'+this.slideNames[this.activeBoxIndex])[0];
      var nextBox = $$('.slides li.'+this.slideNames[index])[0];
      
      if (this.timer) {
        // animation
        currentBox.morph('opacity:0', {
          duration:this.speed,
          after: function() {
            this.updateActiveClasses(this.slideNames[index]);
            nextBox.morph('opacity:1', {duration: this.speed});
          }.bind(this)
        });
      } else {
        this.updateActiveClasses(this.slideNames[index]);
        currentBox.setOpacity(0);
        nextBox.setOpacity(1);
      }
      
      this.activeBoxIndex = index;
    }
  },
  prefixedCSSValue: function(value) {
    return Modernizr.prefixed(value).replace(/([A-Z])/g, function(str,m1){ return '-' + m1.toLowerCase(); }).replace(/^ms-/,'-ms-');
  },
  updateActiveClasses: function(name) {
    $$('body.home .slides li.active').invoke('removeClassName','active');
    $$('body.home .slides_nav a').invoke('removeClassName','active');
    $$('body.home .slides li.'+name).invoke('addClassName','active');
    $$('body.home .slides_nav a.'+name).invoke('addClassName','active');
  },
  setupObservers: function() {
    $$('body.home .slides_nav a').each(function(element){
      element.observe("click", function(e) {
        if (this.timer) {
          clearInterval(this.timer);
          this.timer = null;
        } 
        index = this.slideNames.indexOf(this.getBoxName(element));
        this.nextSlide(index);
        e.preventDefault();
      }.bind(this));
    }.bind(this));
  }
});
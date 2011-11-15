//= require prototype
//= require modernizr

document.observe("dom:loaded", function() {
  // slideshow  = new Slideshow(5,1.1);
});

Slideshow = Class.create({
  initialize: function(pause,speed) {
    this.pauseDuration = pause *1000;
    this.speed = speed;
    this.slideShowWrapper = $$('body.home .slides ul')[0];
    if (Modernizr.csstransitions) {
      this.slideShowWrapper.style[Modernizr.prefixed('transitionDuration')] = this.speed+"s";
      // this.slideShowWrapper.style[Modernizr.prefixed('transitionTimingFunction')] = "cubic-bezier(0, 0, 0.25, 1)";
      if (Modernizr.csstransforms) {
        this.slideShowWrapper.style[Modernizr.prefixed('transitionProperty')] = this.prefixedCSSValue("transform");
      } else {
        this.slideShowWrapper.style[Modernizr.prefixed('transitionProperty')] = "left";
      }
    }
    
    this.slideNames = [];
    $$('body.home .slides li').each(function(element){
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
      var position = index*300;
      if (Modernizr.csstransitions && Modernizr.csstransforms) {
        if (Modernizr.csstransforms3d) {
          this.slideShowWrapper.style[Modernizr.prefixed('transform')] = "translate3d(-" + position + "px, 0, 0)";
        } else {
          this.slideShowWrapper.style[Modernizr.prefixed('transform')] = "translate(-" + position + "px, 0)";
        }
      } else if (Modernizr.csstransitions) {
        this.slideShowWrapper.style.left = "left:-" + position + "px";
      } else {        
        this.slideShowWrapper.morph('left:-'+position+'px', {duration:this.speed});
      }
      
      this.activeBoxIndex = index;
      this.updateActiveClasses(this.slideNames[index]);
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
        if (this.timer) clearInterval(this.timer);
        index = this.slideNames.indexOf(this.getBoxName(element));
        this.nextSlide(index);
        e.preventDefault();
      }.bind(this));
    }.bind(this));
  }
});

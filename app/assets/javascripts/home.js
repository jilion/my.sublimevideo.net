//= require prototype
//= require modernizr
//= require s2

document.observe("dom:loaded", function() {
  slideshow = new Slideshow(4, 0.6);
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
        this.fadeInAnimation = new S2.FX.Morph(currentBox, {
          duration:this.speed,
          style: 'opacity:0',
          after: function() {
            if (this.timer) {
              this.updateActiveClasses(this.slideNames[index]);
              this.fadeOutAnimation = new S2.FX.Morph(nextBox, {
                duration:this.speed,
                style: 'opacity:1'
              });
              this.fadeOutAnimation.play();
            } else {
              currentBox.setOpacity(0);
              
            }
          }.bind(this)
        });
        this.fadeInAnimation.play();
      } else {
        if (this.fadeInAnimation) {
          this.fadeInAnimation.cancel();
          this.fadeInAnimation = null;
        }
        
        if (this.fadeOutAnimation) {
          this.fadeOutAnimation.cancel();
          this.fadeOutAnimation = null;
        }

        this.updateActiveClasses(this.slideNames[index]);
        currentBox.removeAttribute('style');
        currentBox.setOpacity(0);
        nextBox.removeAttribute('style');
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
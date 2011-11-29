document.observe("dom:loaded", function() {
  if ($('features_slides')) {
    slideshow = new Slideshow(4, 0.6);
  }
});

Slideshow = Class.create({
  initialize: function(pause,speed) {
    this.pauseDuration = pause *1000;
    this.speed = speed;
    this.slideShowWrapper = $$('body.home ul.slides')[0];

    this.slideNames = [];
    $$('body.home .slides li').each(function(element){
      if (!element.hasClassName('active')) {
        this.hideElement(element);
      }
      this.slideNames.push(this.getBoxName(element));
    }.bind(this));

    this.activeBoxIndex = 0;
    this.startTimer();
    this.setupObservers();
  },
  isIE: function() {
    return (Prototype.Browser.IE);
  },
  hideElement: function(element) {
    if (this.isIE()) {
      element.hide();
    } else {
      element.show();
      element.setOpacity(0);
    }
  },
  showElement: function(element) {
    if (this.isIE()) {
      element.show();
    } else {
      element.setOpacity(1);
    }
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
      if (this.timer && !this.isIE()) {
        // animation
        this.fadeInAnimation = new S2.FX.Morph(currentBox, {
          duration:this.speed,
          style: 'opacity:0',
          after: function() {
            if (this.timer) {
              currentBox.setStyle({zIndex:'auto'});
              nextBox.setStyle({zIndex:2});
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
        // no timer or ie
        if (this.fadeInAnimation) {
          this.fadeInAnimation.cancel();
          this.fadeInAnimation = null;
        }

        if (this.fadeOutAnimation) {
          this.fadeOutAnimation.cancel();
          this.fadeOutAnimation = null;
        }

        currentBox.setStyle({zIndex:'auto'});

        this.updateActiveClasses(this.slideNames[index]);
        currentBox.removeAttribute('style');
        this.hideElement(currentBox);
        nextBox.removeAttribute('style');
        this.showElement(nextBox);
        nextBox.setStyle({zIndex:2});
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
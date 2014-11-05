var DialogDimensionsAdjuster = function(attributes){
  this.raw = attributes || {'margin': 18};
};

App.attr_reader(DialogDimensionsAdjuster.prototype, ['margin']);

DialogDimensionsAdjuster.prototype.callback = function(){
  var adjuster = this;

  return function(event, ui){
    if ($(this).parent().height() > adjuster.window_height()){
      $(this).dialog('option', 'height', adjuster.window_height() - adjuster.margin() * 2);
    }

    if ($(this).parent().width() + 3 >= adjuster.window_width()){
      $(this).dialog('option', 'width', adjuster.window_width() - adjuster.margin() * 2);
    }

    $(this).dialog('option', 'position', 'center');
  };
};

DialogDimensionsAdjuster.prototype.window_height = function(){
  return $(window).height();
};

DialogDimensionsAdjuster.prototype.window_width = function(){
  return $(window).width();
};

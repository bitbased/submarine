// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
// require jquery.ui.all // jQUERY UI not compatible with bootstrap!!!!!!!
// 
//= require jquery
//= require jquery_ujs
//= require jquery-fileupload/basic
//= require jquery-fileupload/vendor/tmpl
//= require underscore
//= require_tree ./chosen/lib
//= require chosen/chosen
//= require backbone
//= require backbone-relational
//= require submarine
//= require dropbox
//= require_tree ./templates
//= require_tree ./models
//= require_tree ./collections
//= require_tree ./views
//= require_tree ./routers
//= require hamlcoffee


$.fn.selectRange = function(start, end) {
    if(!end) end = start;
    return this.each(function() {
        if (this.setSelectionRange) {
            this.focus();
            this.setSelectionRange(start, end);
        } else if (this.createTextRange) {
            var range = this.createTextRange();
            range.collapse(true);
            range.moveEnd('character', end);
            range.moveStart('character', start);
            range.select();
        }
    });
};

$(function() {

  $('form').on('click', '.add_fields', function(event) {
    var regexp, time;
    time = new Date().getTime();
    regexp = new RegExp($(this).data('id'), 'g');
    $(this).before($(this).data('fields').replace(regexp, time));
    event.preventDefault();
  });

  $('form').on('click', '.remove_fields', function(event) {
    $(this).prev('input[type=hidden]').val('1');
    $(this).closest('fieldset').hide();
    event.preventDefault();
  });

  var check_header = function(){

    if($(".header").innerHeight() > 70)
    {
      if(!$(".layout").hasClass("layout-expanded")) $(".layout").addClass("layout-expanded");
    }else{
      $(".layout.layout-expanded").removeClass("layout-expanded");
    }
    //document.title = $(".header").innerHeight();
    setTimeout(check_header,250);
  }

  setTimeout(check_header,100);
});






$(function(){
  $(".background-action").click(function(){
    $.get($(this).attr("href"));
    return false;
  });
});

$(function(){
  
  $(".dismiss-activity").click(function(){
    $.post("/activity_logs/" + $(this).data("id") + "/dismiss");
  });
  
});










String.prototype.trim=function(){return this.replace(/^\s+|\s+$/g, '');};



function humanHours(d)
{
  d = Number(d)*60;
  var h = Math.floor(d % 3600 / 60);
  var m = Math.floor(d % 3600 % 60);
  return h + ":" + (m < 10 ? "0" : "") + m;
}



function humanDate(dd)
{
    if (dd < new Date() && Math.abs(Math.floor(((new Date()).getTime()-dd.getTime())/1000/60/60/24.0)) < 1)
    {
      dd="TODAY";
    }else if (dd < new Date() && Math.abs(Math.floor(((new Date()).getTime()-dd.getTime())/1000/60/60/24.0)) >= 1)
    {
      var dy = Math.abs(Math.floor(-((new Date()).getTime()-dd.getTime())/1000/60/60/24))-1;
      dd = dy + (dy==1 ? " DAY" : " DAYS") + " LATE";
      
      if(dy > 10)
      {
        dd = Math.floor((dy+2)/7) + (Math.floor((dy+2)/7)==1 ? " WEEK" : " WEEKS") + " LATE";        
      }
      if(dy > 45)
      {
        dd = Math.floor((dy+7)/30) + (Math.floor((dy+7)/30)==1 ? " MONTH" : " MONTHS") + " LATE";        
      }
      
    }else{
      var cy = (new Date()).getFullYear();
      dd = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][dd.getDay()] + " " + ["Jan", "Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][dd.getMonth()] + " " + dd.getDate() + (dd.getFullYear() != cy ? ", " + dd.getFullYear() : "");
    }
  
  return dd;
}


//function formatLinks(dd)
//{
//  exp = /\(?\bhttps?:\/\/[-A-Za-z0-9+&@#\/%?=~_()|!:,.;]*[-A-Za-z0-9+&@#\/%=~_()|]/ig
//  source = source.replace(exp,"$1");
//}

function replaceURLWithHTMLLinks(text) {
    var exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig;
    return text.replace(exp,"<a href='$1'>$1</a>"); 
}

function formatLinks(text) {
  var exp = /(\(?\bhttps?:\/\/[-A-Za-z0-9+&@#\/%?=~_()|!:,.;]*[-A-Za-z0-9+&@#\/%=~_()|])/ig
  return text.replace(exp,"<a class='notes-link' target='_blank' style='color: gray' href='$1'>$1</a>"); 
}



/*
 * Date Format 1.2.3
 * (c) 2007-2009 Steven Levithan <stevenlevithan.com>
 * MIT license
 *
 * Includes enhancements by Scott Trenda <scott.trenda.net>
 * and Kris Kowal <cixar.com/~kris.kowal/>
 *
 * Accepts a date, a mask, or a date and a mask.
 * Returns a formatted version of the given date.
 * The date defaults to the current date/time.
 * The mask defaults to dateFormat.masks.default.
 */

var dateFormat = function () {
  var token = /d{1,4}|m{1,4}|yy(?:yy)?|([HhMsTt])\1?|[LloSZ]|"[^"]*"|'[^']*'/g,
    timezone = /\b(?:[PMCEA][SDP]T|(?:Pacific|Mountain|Central|Eastern|Atlantic) (?:Standard|Daylight|Prevailing) Time|(?:GMT|UTC)(?:[-+]\d{4})?)\b/g,
    timezoneClip = /[^-+\dA-Z]/g,
    pad = function (val, len) {
      val = String(val);
      len = len || 2;
      while (val.length < len) val = "0" + val;
      return val;
    };

  // Regexes and supporting functions are cached through closure
  return function (date, mask, utc) {
    var dF = dateFormat;

    // You can't provide utc if you skip other args (use the "UTC:" mask prefix)
    if (arguments.length == 1 && Object.prototype.toString.call(date) == "[object String]" && !/\d/.test(date)) {
      mask = date;
      date = undefined;
    }

    // Passing date through Date applies Date.parse, if necessary
    date = date ? new Date(date) : new Date;
    if (isNaN(date)) throw SyntaxError("invalid date");

    mask = String(dF.masks[mask] || mask || dF.masks["default"]);

    // Allow setting the utc argument via the mask
    if (mask.slice(0, 4) == "UTC:") {
      mask = mask.slice(4);
      utc = true;
    }

    var _ = utc ? "getUTC" : "get",
      d = date[_ + "Date"](),
      D = date[_ + "Day"](),
      m = date[_ + "Month"](),
      y = date[_ + "FullYear"](),
      H = date[_ + "Hours"](),
      M = date[_ + "Minutes"](),
      s = date[_ + "Seconds"](),
      L = date[_ + "Milliseconds"](),
      o = utc ? 0 : date.getTimezoneOffset(),
      flags = {
        d:    d,
        dd:   pad(d),
        ddd:  dF.i18n.dayNames[D],
        dddd: dF.i18n.dayNames[D + 7],
        m:    m + 1,
        mm:   pad(m + 1),
        mmm:  dF.i18n.monthNames[m],
        mmmm: dF.i18n.monthNames[m + 12],
        yy:   String(y).slice(2),
        yyyy: y,
        h:    H % 12 || 12,
        hh:   pad(H % 12 || 12),
        H:    H,
        HH:   pad(H),
        M:    M,
        MM:   pad(M),
        s:    s,
        ss:   pad(s),
        l:    pad(L, 3),
        L:    pad(L > 99 ? Math.round(L / 10) : L),
        t:    H < 12 ? "a"  : "p",
        tt:   H < 12 ? "am" : "pm",
        T:    H < 12 ? "A"  : "P",
        TT:   H < 12 ? "AM" : "PM",
        Z:    utc ? "UTC" : (String(date).match(timezone) || [""]).pop().replace(timezoneClip, ""),
        o:    (o > 0 ? "-" : "+") + pad(Math.floor(Math.abs(o) / 60) * 100 + Math.abs(o) % 60, 4),
        S:    ["th", "st", "nd", "rd"][d % 10 > 3 ? 0 : (d % 100 - d % 10 != 10) * d % 10]
      };

    return mask.replace(token, function ($0) {
      return $0 in flags ? flags[$0] : $0.slice(1, $0.length - 1);
    });
  };
}();

// Some common format strings
dateFormat.masks = {
  "default":      "ddd mmm dd yyyy HH:MM:ss",
  shortDate:      "m/d/yy",
  mediumDate:     "mmm d, yyyy",
  longDate:       "mmmm d, yyyy",
  fullDate:       "dddd, mmmm d, yyyy",
  shortTime:      "h:MM TT",
  mediumTime:     "h:MM:ss TT",
  longTime:       "h:MM:ss TT Z",
  isoDate:        "yyyy-mm-dd",
  isoTime:        "HH:MM:ss",
  isoDateTime:    "yyyy-mm-dd'T'HH:MM:ss",
  isoUtcDateTime: "UTC:yyyy-mm-dd'T'HH:MM:ss'Z'"
};

// Internationalization strings
dateFormat.i18n = {
  dayNames: [
    "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat",
    "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
  ],
  monthNames: [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"
  ]
};

// For convenience...
Date.prototype.format = function (mask, utc) {
  if(utc == null) utc = true;
  return dateFormat(this, mask, utc);
};
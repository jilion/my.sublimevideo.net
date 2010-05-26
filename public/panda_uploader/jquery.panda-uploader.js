(function(){

var UPLOADING = 0;
var STOP = 1;

var num_files = 0;
var num_pending = 0;
var num_errors = 0;

var status = STOP;

jQuery.fn.pandaUploader = function(signed_params, options, swfupload_options) {
    var $video_field = this;

    if (signed_params === undefined) {
        alert("There was an error setting up the upload form. (The upload parameters were not specified).");
        return false;
    }
    
    options = options === undefined ? {} : options;
    swfupload_options = swfupload_options === undefined ? {} : swfupload_options;
    
    if (options.upload_button_id === undefined) {
        alert("You have to specify the button id");
        return false;
    }
    
    if ($video_field.size() == 0) {
        alert("The jQuery element is empty. Method pandaUploader() cannot be executed");
        return false;
    }
    
    if ( ! form()) {
        alert("Could not find a suitable form. Please place the call to pandaUploader() after the form, or to be executed onload().");
        return false;
    }
    
    if ($j(form()).find('[name=submit], #submit').length != 0) {
        alert("An element of your video upload form is incorrect (most probably the submit button). Neither NAME nor ID can be set to \"submit\" on any field.");
        return false;
    }
    
    
		var $cancel_button = jQuery('#' + options.upload_cancel_button_id);
		if ($cancel_button) {
			$cancel_button.click(onCancel);
		}
    
    options = jQuery.extend({
        upload_filename_id: null,
        upload_progress_id: null,
        api_host: 'api.pandastream.com',
        progress_handler: null,
        uploader_dir: "/panda_uploader",
        disable_submit_button: false
    }, options);
    options['api_url'] = options['api_url'] || 'http://' + options['api_host'] + '/v2';
    
    if (!options.progress_handler) {
        options.progress_handler = new ProgressUpload(options);
    }
    
    var uploader = this.swfupload(jQuery.extend({
        upload_url: options.api_url + '/videos.json',
        file_size_limit : 0,
        file_types : "*.*",
        file_types_description : "All Files",
        file_upload_limit : 0,
        flash_url : options.uploader_dir + "/swfupload.swf",
        button_image_url : options.uploader_dir + "/choose_file_button.png",
        button_window_mode: SWFUpload.WINDOW_MODE.TRANSPARENT,
        button_width : 236,
        button_height : 40,
        button_placeholder_id : options.upload_button_id,
        post_params : signed_params,
        file_post_name: "file",
        debug: false
    }, swfupload_options));
    
    uploader.bind('swfuploadLoaded', onLoad);
    uploader.bind('fileQueued', onFileQueued);
    uploader.bind('uploadStart', onStart);
    uploader.bind('uploadProgress', onProgress);
    uploader.bind('uploadSuccess', onSuccess);
    uploader.bind('uploadError', onError);
    uploader.bind('uploadComplete', onComplete);
    
    return uploader;
    
    function disableSubmitButton(value) {
      if (value == true) {
        $video_field.siblings('object').width(0);
        $video_field.siblings('object').height(0);
      }
      var form = $video_field.parents("form").eq(0);
      form.find("input[type=submit]").each(function() {
       $j(this).attr("disabled", value);
      });
    }
    
    //
    // Event handlers
    //
    
    function onLoad() {
      var form = $video_field.parents("form").eq(0);
      form.submit(onSubmit);
      if(options.disable_submit_button) {
        disableSubmitButton(true);
      }
    }

    function onFileQueued(event, file) {
        num_files++;
        num_pending++;
        var $upload_filename = $j('#' + options.upload_filename_id);
        $upload_filename.html(file.name);
        disableSubmitButton(true);
        onSubmit(event);
    }

    function onSubmit(event) {
      if (num_files > 0) {
        uploader.swfupload('startUpload');
        return false;
      }
    }

    function onStart(event, file) {
      status = UPLOADING;
      uploader.swfupload('setButtonDisabled', true);
      options.progress_handler.reset();
      
      disableSubmitButton(true);
      if (options.progress_handler) {
          options.progress_handler.start(file);
      }
    }

    function onCancel(event) {
      uploader.swfupload('cancelUpload', '', false);
      uploader.swfupload('setButtonDisabled', false);
      
      $j('#' + options.upload_filename_id).val('');
      options.progress_handler.reset();
      num_files = 0;
      num_pending = 0;
      num_errors = 0;
      disableSubmitButton(true);
      
      var cancel_handler = options["cancel"];
      if(status == UPLOADING && cancel_handler) {
        cancel_handler(event);
      }
      status = STOP;
    }
    
    function onProgress(event, file, bytesLoaded, bytesTotal) {
        try {
          if (options.progress_handler) {
              options.progress_handler.setProgress(file, bytesLoaded, bytesTotal);
          }
        } catch (ex) {}
    }

    function onSuccess(event, file, response) {
        $video_field.val(eval('(' + response + ')').id);
        num_pending--;
        
        var success_handler = options["success"];
        if (success_handler) {
          success_handler(event, file, response);
        }
    }

    function onError(event, file, code, message, more) {
        $j('#' + options.upload_filename_id).val('');
        options.progress_handler.reset();
        
        num_pending--;
        num_errors++;

        var error_handler = options["error"];
        if (error_handler) {
          error_handler(event, file, message);
        } else {
          alert("There was an error uploading the file.\n\nHTTP error code " + message);
        }
    }

    function onComplete(event, num_uploads) {
      if (num_files > 0 && num_pending <= 0 && num_errors <= 0) {
        if ( ! $video_field.val()) {
            alert('The video ID was not stored on the form');
            return;
        }

        status = STOP;
        var complete_handler = options["complete"];
        if (complete_handler) {
          complete_handler(event);
        } else {
          form().submit(); 
        }
      }
    }
    
    
    //
    // Utils
    //
    
    function form() {
      return $video_field.parents("form")[0];
    }
};


//
// A simple progress bar
//

function ProgressUpload(options) {
    this.options = options;
    this.$p = jQuery('#' + this.options.upload_progress_id);
    this.$p.css('display', 'none');
    this.count = 0;
}

ProgressUpload.prototype = {
    start: function(file) {
        this.count = 0;
        
        this.progress = this.$p.find('.progress');
        this.setProgress(file, 0, file.size);
        this.$p.css('display', 'block');
        var self = this;
        // this.timer = setInterval(function(){self.animateBarBg();}, 20);
    },
    
    setProgress: function(file, bytesLoaded, bytesTotal) {
        if ( ! this.progress) {
            return;
        }
        var percent = Math.ceil((bytesLoaded / bytesTotal) * 100);
        $j(this.progress).css('width', percent + '%');
        $j('#percent_completed').html(percent + '%');
    },
    
    // animateBarBg: function() {
    //   this.count++;
    //   var currentOffset = parseInt(this.$p.css("background-position").split(" "),10);
    //   if (this.count == 37) {
    //     this.count = 0;
    //     this.$p.css("background-position", (currentOffset + 36) + "px 0px");
    //   }
    //   else
    //     this.$p.css("background-position", (currentOffset - 1) + "px 0px");
    // },
    
    reset: function(){
      clearInterval(this.timer);
      $j(this.progress).css('width', '0%');
      this.$p.css('display', 'none');
    }
};

})();
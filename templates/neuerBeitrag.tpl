<link href="assets/css/jquery.fileupload-ui.css" rel="stylesheet">
<script type="text/javascript">
    $(document).ready(function(){ 
        $('.datepicker').datepicker();
    });
</script>
<div class="form-horizontal well">    
    <a href="bilderGalerie.php" class="btn btn-primary start" style="float: right;"><i class=" icon-remove-circle icon-white"></i></a>
    <!-- The file upload form used as target for the file upload widget -->
    <form id="mainUpload" action="bilderGalerie.php" method="POST">
        <div class="control-group">
            <label for="beitragTitel" class="span3">Titel:</label>
            <input style="width: 450px;" type="text" id="beitragTitel" name="beitragTitel" value="<?php if(isset($beitragTitel)){echo $beitragTitel; }?>">
        </div>

        <div class="control-group">
            <label for="beitragUnterTitel" class="span3">Untertitel:</label>
            <input style="width: 450px;" type="text" id="beitragUnterTitel" name="beitragUnterTitel" value="<?php if(isset($beitragUnterTitel)){echo $beitragUnterTitel; }?>">
        </div>

        <div class="control-group">
            <label class="span3" for="beitragText">Text:</label>
            <textarea class="span6" rows="5" id="beitragtext" name="beitragText"><?php if(isset($beitragtext)){echo $beitragtext; }?></textarea>
        </div>
        <div class="control-group">
            <label class="span3" for="beitragText">Datum:</label>
            <div style="margin-left: 0px; padding-left: 0px;" class="input-append date datepicker" id="dp3" data-date="<?php if(isset($datum)) { echo $datum; } else { echo date('d\.m\.Y'); }  ?>" data-date-format="dd.mm.yyyy">
                <input class="span2" size="16" type="text" value="<?php if(isset($datum)) { echo $datum; } else { echo date('d\.m\.Y'); } ?>" name="event_date">
                <span class="add-on"><i class="icon-th"></i></span>
            </div>
        </div>
        <div class="control-group">
            <span class="span3"><input type="submit" value="Speichern" class="btn btn-primary start"></span>
        </div>
    </form>
    <form id="fileupload" action="server/" method="POST" enctype="multipart/form-data">
    <div class="control-group fileupload-buttonbar">
        <div class="span7">
            <span class="btn btn-success fileinput-button">
                    <i class="icon-plus icon-white"></i>
                    <span>Bilder ausw&auml;hlen...</span>
                    <input type="file" name="files[]" multiple="">
            </span>
            <button type="submit" class="btn btn-primary start">
                <i class="icon-upload icon-white"></i>
                <span>Start upload</span>
            </button>
            <!--<button type="reset" class="btn btn-warning cancel">
                <i class="icon-ban-circle icon-white"></i>
                <span>Cancel upload</span>
            </button>-->
            <button type="button" class="btn btn-danger delete">
                <i class="icon-trash icon-white"></i>
                <span>L&ouml;schen</span>
            </button>
            <input type="checkbox" class="toggle">
        </div>
        <!-- The global progress information -->
        <div class="span3 fileupload-progress fade">
            <!-- The global progress bar -->
            <div class="progress progress-success progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100">
                    <div class="bar" style="width:0%;"></div>
            </div>
            <!-- The extended global progress information -->
            <div class="progress-extended">&nbsp;</div>
        </div>
    </div>
    <!-- The loading indicator is shown during file processing -->
    <div class="fileupload-loading"></div>
    <!-- The table listing the files available for upload/download -->
    <table role="presentation" class="table table-striped"><tbody class="files" data-toggle="modal-gallery" data-target="#modal-gallery"></tbody></table>
    </form>
</div>
</div>
<!-- The template to display files available for upload -->
<script id="template-upload" type="text/x-tmpl">
{% for (var i=0, file; file=o.files[i]; i++) { %}
    <tr class="template-upload fade">
        <td class="preview"><span class="fade"></span></td>
        <td class="name"><span>{%=file.name%}</span></td>
        <td class="size"><span>{%=o.formatFileSize(file.size)%}</span></td>
        {% if (file.error) { %}
            <td class="error" colspan="2"><span class="label label-important">{%=locale.fileupload.error%}</span> {%=locale.fileupload.errors[file.error] || file.error%}</td>
        {% } else if (o.files.valid && !i) { %}
            <td>
                <div class="progress progress-success progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0"><div class="bar" style="width:0%;"></div></div>
            </td>
            <td class="start">{% if (!o.options.autoUpload) { %}
                <button class="btn btn-primary">
                    <i class="icon-upload icon-white"></i>
                    <span>{%=locale.fileupload.start%}</span>
                </button>
            {% } %}</td>
        {% } else { %}
            <td colspan="2"></td>
        {% } %}
        <td class="cancel">{% if (!i) { %}
            <button class="btn btn-warning">
                <i class="icon-ban-circle icon-white"></i>
                <span>{%=locale.fileupload.cancel%}</span>
            </button>
        {% } %}</td>
    </tr>
{% } %}
</script>
<!-- The template to display files available for download -->
<script id="template-download" type="text/x-tmpl">
{% for (var i=0, file; file=o.files[i]; i++) { %}
    <tr class="template-download fade">
        {% if (file.error) { %}
            <td></td>
            <td class="name"><span>{%=file.name%}</span></td>
            <td class="size"><span>{%=o.formatFileSize(file.size)%}</span></td>
            <td class="error" colspan="2"><span class="label label-important">{%=locale.fileupload.error%}</span> {%=locale.fileupload.errors[file.error] || file.error%}</td>
        {% } else { %}
            <td class="preview">{% if (file.thumbnail_url) { %}
                <a href="{%=file.url%}" title="{%=file.name%}" rel="gallery" download="{%=file.name%}"><img src="{%=file.thumbnail_url%}"></a>
            {% } %}</td>
            <td class="name">
                <a href="{%=file.url%}" title="{%=file.name%}" rel="{%=file.thumbnail_url&&'gallery'%}" download="{%=file.name%}">{%=file.name%}</a>
            </td>
            <td class="size"><span>{%=o.formatFileSize(file.size)%}</span></td>
            <td colspan="2"></td>
        {% } %}
        <td class="delete">
            <button class="btn btn-danger" data-type="{%=file.delete_type%}" data-url="{%=file.delete_url%}">
                <i class="icon-trash icon-white"></i>
                <span>L&ouml;schen</span>
            </button>
            <input type="checkbox" name="delete" value="1">
        </td>
    </tr>
{% } %}
</script>
<!-- The jQuery UI widget factory, can be omitted if jQuery UI is already included -->
<script src="assets/js/vendor/jquery.ui.widget.js"></script>
<!-- The Templates plugin is included to render the upload/download listings -->
<script src="http://blueimp.github.com/JavaScript-Templates/tmpl.min.js"></script>
<!-- The Load Image plugin is included for the preview images and image resizing functionality -->
<script src="http://blueimp.github.com/JavaScript-Load-Image/load-image.min.js"></script>
<!-- The Canvas to Blob plugin is included for image resizing functionality -->
<script src="http://blueimp.github.com/JavaScript-Canvas-to-Blob/canvas-to-blob.min.js"></script>
<!-- Bootstrap JS and Bootstrap Image Gallery are not required, but included for the demo -->
<script src="http://blueimp.github.com/cdn/js/bootstrap.min.js"></script>
<script src="http://blueimp.github.com/Bootstrap-Image-Gallery/js/bootstrap-image-gallery.min.js"></script>
<!-- The Iframe Transport is required for browsers without support for XHR file uploads -->
<script src="assets/js/jquery.iframe-transport.js"></script>
<!-- The basic File Upload plugin -->
<script src="assets/js/jquery.fileupload.js"></script>
<!-- The File Upload file processing plugin -->
<script src="assets/js/jquery.fileupload-fp.js"></script>
<!-- The File Upload user interface plugin -->
<script src="assets/js/jquery.fileupload-ui.js"></script>
<!-- The localization script -->
<script src="assets/js/locale.js"></script>
<!-- The main application script -->
<script src="assets/js/main.js"></script>
<!-- bilder slider braucht auch jquery-->
<script src="assets/js/jquery.orbit-1.2.3.min.js"></script>
<!-- The XDomainRequest Transport is included for cross-domain file deletion for IE8+ -->
<!--[if gte IE 8]><script src="js/cors/jquery.xdr-transport.js"></script><![endif]-->
<h1>Neuer Beitrag</h1>
<br />
<div style="clear:both;">
   <label style="float:left; width:130px;" for="beitragTitel" class="control-label">Titel:</label>
   <input type="text" style="float:left; width:300px;" class="span2" id="beitragTitel" name="beitragTitel">
</div>

<div style="clear:both;">
   <label style="float:left; width:130px;" for="beitragUnterTitel" class="control-label">Untertitel:</label>
   <input type="text" style="float:left; width:300px;" class="span2" id="beitragUnterTitel" name="beitragUnterTitel">
</div>

<div style="clear:both;">
   <label style="float:left; width:130px;" for="beitragText" class="control-label">Titel</label>
   <textarea rows="8" cols="100" style="width:300px;" id="beitragtext" name="beitragText"></textarea> 
</div>
<a href="bilderGalerie.php" class="btn btn-success">Save</a>
<br />
<!-- The file upload form used as target for the file upload widget -->
    <form style="clear:both;" id="fileupload" action="server/php/" method="POST" enctype="multipart/form-data">
        <!-- The fileupload-buttonbar contains buttons to add/delete files and start/cancel the upload -->
        <div class="row fileupload-buttonbar">
            <div class="span7">
                <!-- The fileinput-button span is used to style the file input field as button -->
                <span class="btn btn-success fileinput-button">
                    <i class="icon-plus icon-white"></i>
                    <span>Bilder hinzufügen</span>
                    <input type="file" name="files[]" multiple>
                </span>
                <button type="submit" class="btn btn-primary start">
                    <i class="icon-upload icon-white"></i>
                    <span>Upload starten</span>
                </button>
                <!--<button type="reset" class="btn btn-warning cancel">
                    <i class="icon-ban-circle icon-white"></i>
                    <span>Cancel upload</span>
                </button>-->
                <button type="button" class="btn btn-danger delete">
                    <i class="icon-trash icon-white"></i>
                    <span>Löschen</span>
                </button>
                <input type="checkbox" class="toggle">
            </div>
            <!-- The global progress information -->
            <div class="span5 fileupload-progress fade">
                <!-- The global progress bar -->
                <div class="progress progress-success progress-striped active">
                    <div class="bar" style="width:0%;"></div>
                </div>
                <!-- The extended global progress information -->
                <div class="progress-extended">&nbsp;</div>
            </div>
        </div>
        <!-- The loading indicator is shown during file processing -->
        <div class="fileupload-loading"></div>
        <br>
        <!-- The table listing the files available for upload/download -->
        <table class="table table-striped"><tbody class="files" data-toggle="modal-gallery" data-target="#modal-gallery"></tbody></table>
    </form>
 </div>
 <!-- modal-gallery is the modal dialog used for the image gallery -->
 <div id="modal-gallery" class="modal modal-gallery hide fade" data-filter=":odd">
    <div class="modal-header">
        <a class="close" data-dismiss="modal">&times;</a>
        <h3 class="modal-title"></h3>
    </div>
    <div class="modal-body"><div class="modal-image"></div></div>
    <div class="modal-footer">
        <a class="btn modal-download" target="_blank">
            <i class="icon-download"></i>
            <span>Download</span>
        </a>
        <a class="btn btn-success modal-play modal-slideshow" data-slideshow="5000">
            <i class="icon-play icon-white"></i>
            <span>Slideshow</span>
        </a>
        <a class="btn btn-info modal-prev">
            <i class="icon-arrow-left icon-white"></i>
            <span>Previous</span>
        </a>
        <a class="btn btn-primary modal-next">
            <span>Next</span>
            <i class="icon-arrow-right icon-white"></i>
        </a>
    </div>

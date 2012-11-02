<?php
require('upload.class.php');

class CustomUploadHandler extends UploadHandler {
    protected function get_user_id() {
        @session_start();
        return $_SESSION["uploadFolder"];
    }
}

$upload_handler = new CustomUploadHandler(array(
    'user_dirs' => true,
    'download_via_php' => true
));
?>
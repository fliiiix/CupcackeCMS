<?php include 'templates/header.tpl'; ?>
<?php 
unset($errormsg);
if ((isset($_Post["beitragTitel"])) && (3 > strlen($titel))) {
	$errormsg = "Es muss ein Titel haben der Länger als 3 Zeichen ist.<br />" . $errormsg;
}
elseif ((isset($_Post["beitragText"])) && (3 > strlen($text))) {
	$errormsg = "Es muss ein Text haben der Länger als 3 Zeichen ist.<br />" . $errormsg;
}
elseif (($_FILES['filesToUpload']) != null) {
	$errormsg = "Es müssen bilder aus gewählt werden.<br />" . $errormsg;
}
if(!isset($errormsg)){
	$titel = $_Post["beitragTitel"];
	$unterTitel = $_Post["beitragUnterTitel"];
	$text = $_Post["beitragText"];
	$num_files = count($_FILES['filesToUpload']['name']);

	for ($i=0; $i < $num_files ; $i++) { 
  	if(($_FILES['filesToUpload']['type'][$i] == 'image/pjpeg') || 
  	   ($_FILES['filesToUpload']['type'][$i] == 'image/jpeg') || 
  	   ($_FILES['filesToUpload']['type'][$i] == 'image/gif') || 
  	   ($_FILES['filesToUpload']['type'][$i] == 'image/jpg') || 
  	   ($_FILES['filesToUpload']['type'][$i] == 'image/png') || 
  	   ($_FILES['filesToUpload']['type'][$i] == 'image/x-png')){
	  		$time_var=time();
			$file_tmp=$_FILES['filesToUpload']['tmp_name'][$i];
			//$file_new='upload/files/'.-folderName-.'/'.$time_var.'_'.$_FILES['upload']['name'][$i];    

		    // Bild hochladen
		    move_uploaded_file($file_tmp,$file_new);

		    // Rechte setzen
		    chmod($file_new, 0777);

		    // z.B. Datenbankanbindung
		    // mysql_query("blabla......");
  		}
	}
}
?>
<script type="text/javascript">
		function makeFileList() {
			var input = document.getElementById("filesToUpload");
			var ul = document.getElementById("fileList");
			while (ul.hasChildNodes()) {
				ul.removeChild(ul.firstChild);
			}
			for (var i = 0; i < input.files.length; i++) {
				var li = document.createElement("li");
				li.innerHTML = input.files[i].name;
				ul.appendChild(li);
			}
			if(!ul.hasChildNodes()) {
				var li = document.createElement("li");
				li.innerHTML = 'No Files Selected';
				ul.appendChild(li);
			}
		}
</script>

<div class="row">
		<span class="span2"><a href="bilderGalerie.php?neu=true" class="btn btn-primary">Neuer Beitrag</a></span>
		<?php if (isset($errormsg))
		{ echo $errormsg; }
	 	?>
</div>
<br />
<form method="post" action="bilderGalerie.php" enctype="multipart/form-data" class="form-horizontal well">
	<legend>Neuer Beitrag</legend>
	<div class="control-group">
	   <label class="span3" for="beitragTitel" class="control-label">Titel:</label>
	   <input type="text" id="beitragTitel" name="beitragTitel">
	</div>

	<div class="control-group">
	   <label class="span3" for="beitragUnterTitel" class="control-label">Untertitel:</label>
	   <input type="text" id="beitragUnterTitel" name="beitragUnterTitel">
	</div>

	<div class="control-group">
	   <label class="span3" for="beitragText" class="control-label">Text:</label>
	   <textarea class="span6" rows="5" id="beitragtext" name="beitragText"></textarea> 
	</div>
	<div class="control-group">
		<span class="span3">
			<input type="submit" value="Speichern" class="btn btn-primary start">  
		</span>
	</div>
	<div class="control-group">
		<span class="span3">
				 <span class="btn btn-success fileinput-button">
					<i class="icon-plus icon-white"></i>
					<span>Datein ausw&auml;hlen...</span>
				    <input name="filesToUpload[]" id="filesToUpload" type="file" multiple="" onChange="makeFileList();" />
				</span> 
		</span>
		<span class="span8">
			 <ul id="fileList">
			 	<li>empty</li>
			 </ul>
		</span>
	</div>
</form>

<?php
 if (isset($_GET["neu"]) == "true")
 {
     //include 'templates/neuerBeitrag.tpl';-->
 }
?> 
<?php include 'templates/footer.tpl'; ?>


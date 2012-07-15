<?php include 'templates/header.tpl'; ?>
<a href="bilderGalerie.php?neu=true" class="btn btn-primary">Neuer Beitrag</a>
<?php
 if (isset($_GET["neu"]) == "true")
 {
     include 'neuerBeitrag.tpl';
 }
?> 
<?php include 'templates/footer.tpl'; ?>


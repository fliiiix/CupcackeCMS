<html>
<head>
<link href="main.css" rel="stylesheet" type="text/css">
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Startseite</title>
</head>
<div id="headerDiv">
	<form action="loggin.php" method="post">
		<label for="userName">Username</label> 
		<input type="text" name="userName">
		
		<label for="passwort">Passwort</label> 
		<input type="password" name="passwort">
		
		<input type="submit" value="Einlogen">
	</form>
</div>
<div id="mainDiv">
<h1>Regiesriere dich jetzt!</h1>
	<form action="createUser.php" method="post">
		<label for="userName">Username</label> 
		<input type="text" name="createuserName">
		
		<label for="passwort">Passwort</label> 
		<input type="password" name="createpasswort">
		
		<input type="submit" value="Account erstellen">
	</form>
</div>
</html>
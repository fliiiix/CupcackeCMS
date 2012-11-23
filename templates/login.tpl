<li id="login">
    <form method="post" action="" class="navbar-form">
       <p class="navbar-text" style="float:left;">Email:&nbsp;&nbsp;&nbsp;</p> 
       <input type="text" name="email" id="email" class="span2" style="float:left; width:120px;"/>

       <p class="navbar-text" style="float:left;">&nbsp;&nbsp;&nbsp;Passwort:&nbsp;&nbsp;&nbsp;</p> 
       <input type="password" name="password" id="password" class="span2" style="float:left; width:100px;"/>

       <div class="btn-group" style="float:left;">
           <button type="submit" class="btn btn-primary" id="login_button" name="login_button">Einloggen</button>
           <a class="btn btn-primary dropdown-toggle" data-toggle="dropdown" href="#"><span class="caret"></span></a>
           <ul class="dropdown-menu">
              <li><a href="recover_password.php">Passwort vergessen</a></li>
          </ul>
       </div><!-- /btn-group -->
    </form>
</li>
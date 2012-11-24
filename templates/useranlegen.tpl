<div id="create_user">
    <div>
        <form method="post">
            <table>
                <tr>
                    <td><b>E-Mail-Adresse des Nutzers:</b></td> 
                    <td><input name="email" type="text" maxlength="256" value="<?php if(isset($email)){echo $email; }?>"></td> 
                </tr>
                <tr>
                    <td><b>E-Mail-Adresse des Nutzers bestätigen:</b></td>
                    <td><input name="email_retype" type="text" maxlength="256" value="<?php if(isset($email2)){echo $email2; }?>"></td>
                </tr>
                <tr>
                    <td><b>Vorname des Nutzers:</b></td>
                    <td><input name="vorname" type="text" maxlength="256" value="<?php if(isset($vorname)){echo $vorname; }?>"></td>
                </tr>
                <tr>
                    <td><b>Nachname des Nutzers:</b></td>
                    <td><input name="nachname" type="text" maxlength="256" value="<?php if(isset($nachname)){echo $nachname; }?>"></td>
                </tr>
                <tr>
                    <td><b>Rolle des Nutzers:</b> </td>
                    <td>
                        <select size="1" name="rolle">
                            <option value="1" <?php if(isset($rolle) && $rolle == 1) { echo 'selected'; } ?>>Nutzer</option>
                            <option value="2" <?php if(isset($rolle) && $rolle == 2) { echo 'selected'; } ?>>Admin</option>
                        </select>
                    </td>
                </tr>
            </table>
            <input class="btn btn-primary" type="submit" value="Nutzer erstellen" name="create_user">
        </form>
    </div>
</div>

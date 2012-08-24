<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <meta http-equiv="content-language" content="de" />
  <meta name="generated" content="15.03.2009" />
  <meta name="author" content="Alexander Bogomolov" />
  <meta name="robots" content="index,follow" />
  <meta name="title" content="Kalender mit PHP erstellen" />
  <meta name="keywords" content="Erstellen Sie einen ganz individuellen Kalender für ihre Webseite." />
  <meta name="description" content="" />

  <title>Kalender mit PHP erstellen</title>
</head>
<body>
<?php
$month = isset($_GET['month']) ? intval($_GET['month']) : date('n');
$year = isset($_GET['year']) ? intval($_GET['year']) : date('Y');
$options['today_class'] = "background-color:#FFFF00; font-weight:bold; color:#5F98B5;";
$weekdays = array('Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So');
$prev_symbol = "«";
$next_symbol = "»";
$summary = "Mein erster Kalender";
$caption = "Kalender";
$options['month_link'] 	= '<a href="'.$_SERVER['PHP_SELF'].'?month=%d&amp;year=%d">%s</a>';
$total_days = date('t', mktime(0, 0, 0, $month, 1, $year));
$day_offset = date('w', mktime(0, 0, 0, $month, 1, $year));
list($n_month, $n_year, $n_day) = split(', ', strftime('%m, %Y, %d'));
$day_highlight = (($n_month == $month) &amp;&amp; ($n_year == $year));
list($n_prev_month, $n_prev_year) = split(', ', strftime('%m, %Y', mktime(0, 0, 0, $month-1, 1, $year)));
$prev_month_link = sprintf($options['month_link'], $n_prev_month, $n_prev_year, $prev_symbol);
list($n_next_month, $n_next_year) = split(', ', strftime('%m, %Y', mktime(0, 0, 0, $month+1, 1, $year)));
$next_month_link = sprintf($options['month_link'], $n_next_month, $n_next_year, $next_symbol);
echo '
<table border="0" summary="'.$summary.'">
<caption>'.$caption.'</caption>
<thead>
<tr>
<th>'.$prev_month_link.'</th>
<th colspan="5">'.strftime('%B %Y', mktime(0, 0, 0, $month, 1, $year)).'</th>
<th>'.$next_month_link.'</th>
</tr>';
echo "<tr>\n";
foreach ($weekdays as $weekday)
{
  echo "\t";
  echo "<th>".$weekday."</th>\n";
  echo "\n";
}
echo "\n";
echo "\n";
echo "</tr>
</thead>
<tbody>\n";
echo "<tr>\n";
if ($day_offset > 0) {
  for ($i=0; $i<$day_offset; $i++)
  {
    echo "\t";
    echo '<td class="empty_cell">';
    echo "\n";
   } 
 }
 for ($day=1; $day<=$total_days; $day++)
{
  if ($day_highlight && ($day == $n_day))
  {
      echo "\t";
      echo '</td>
       <td id="day_'.$day.'" style="'.$options['today_class'].'">'.$day.'';
       echo "\n";
   }   else   {
     echo "\t";
     echo '</td>
<td id="day_'.$day.'">'.$day.'</td>';
     echo "\n";
   }
   $day_offset++;
    if ($day_offset == 7)   {
     $day_offset = 0;
     if ($day < $total_days)
     {
       echo "</tr>\n<tr>";
     }
   }
 }
 if ($day_offset > 0)
{
  $day_offset = 7-$day_offset;
}
if ($day_offset > 0)
{
  for ($i=0; $i< $day_offset; $i++)
  {
    echo '<td class="empty_cell">';
     echo "\n";
  }
}
echo '</td>
</tr>
</tbody></table>
';
?>
</body>
</html>
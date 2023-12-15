# Recording Instructions:

1. Start a Garmin activity with "Auto Lap = Manual Only" and "Lap Key = On"
2. Press the Lap button to create breakpoints in the match, for example
   i) there is a long break in play, e.g. due to an injury;
   ii) at the start and end of half time.
3. Press 'Stop' and 'Save' at full time.

# Using the app

1. Go to Garmin Connect, select the acivity, and click 'Export Original'.
2. Unzip the .zip file to obtain the .fit file.
3. Open the app in R via `shiny::runGitHub(repo ="garmin-football", username = "pawleymatthew")`.
4. Upload the .fit file.
5. Set the pitch boundaries by placing the markers at the corners. The marker labels indicate the positions ("RB" = right back, "RF" = right forward etc.) with respect to the **1st half** direction of attack. You can toggle between OpenStreetView and Satellite map views; one may be better than the other depending on the location. 
6. Select which laps to include as 1st half and 2nd half. Uncheck laps (e.g. the half time lap) will not contribute to the heatmap. (2nd half laps will be flipped; if you did not swap ends at half time, then designate the 2nd half laps as 1st half laps.)
7. Set a title and subtitle for the plot, if desired.
8. Click 'Generate heatmap' to make the graphic. Thereafter, the graphic will update automatically when inputs are updated. (The plot will momentarily give an error if you change the input file; this will disappear after the file is processed.)
9. Click 'Download' to save the plot as a PNG file. 

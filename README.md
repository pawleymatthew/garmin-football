Run the app: `shiny::runGitHub(repo ="garmin-football", username = "pawleymatthew")`

# Recording Instructions:

1. Start a Garmin activity with "Auto Lap = Manual Only" and "Lap Key = On"
2. Press the Lap button to create breakpoints in the match, for example
   i) at the start and end of a long break in play, e.g. due to an injury;
   ii) at the start and end of the half time break.
3. Press 'Stop' and 'Save' at full time.

# Using the app

1. Go to Garmin Connect, select the acivity, and click 'Export Original'.
2. Extract the the .fit file from the .zip file.
3. Run the app in R via `shiny::runGitHub(repo ="garmin-football", username = "pawleymatthew")`.
4. Upload the .fit file.
5. Set the pitch boundaries by placing the markers at the corners, toggling between the OpenStreetView and Satellite map views if necessary. The marker labels indicate the positions ("RB" = right back, "RF" = right forward etc.) with respect to the **1st half** direction of attack. 
6. Select which half (1st/2nd) each lap was part of. Laps that you don't want to contribute to the heatmap (e.g. a break in injury) should be left unchecked. The only effect of designating halves is that 2nd half laps will be flipped. If you did not swap ends at half time, then designate all laps as 1st half.
7. Set a title and subtitle for the plot, if desired.
8. Click 'Generate heatmap' to make the graphic. Thereafter, the graphic will update automatically when inputs are updated. (The plot will momentarily give an error if you change the input file; this will disappear after the file is processed.)
9. Click 'Download' to save the plot as a PNG file. 

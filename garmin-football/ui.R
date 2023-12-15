library(shiny)
library(leaflet)

fluidPage(

    # side bar for inputs
    sidebarPanel(
        fileInput(inputId = "file", label = "", accept = ".fit", buttonLabel = "Select file..."),
        hr(),
        leafletOutput("map"),
        hr(),
        checkboxGroupInput(inputId = "first_laps", label = "1st half", choices = 1:3, inline = TRUE),
        checkboxGroupInput(inputId = "second_laps", label = "2nd half", choices = 1:3, inline = TRUE),
        hr(),
        textInput(inputId = "title", label = "", value = "", placeholder = "Plot title..."),
        textInput(inputId = "subtitle", label = "", value = "", placeholder = "Plot subtitle..."),
        actionButton("goHeatmap", "Generate heatmap"),
        downloadButton('downloadHeatmap', 'Download'),
        width = 6
    ),
    
    # main panel for outputs
    mainPanel(
        #tableOutput("marker_table"),
        #tableOutput("xy_basis"),
        plotOutput("heatmap"),
        #plotOutput("run"),
        width = 6
    )
)

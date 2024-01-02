library(shiny)
library(dplyr)
library(tidyr)
library(FITfileR)
library(magrittr)
library(leaflet)
library(leaflet.extras2)
library(pracma)
library(soccermatics)
library(ggplot2)
library(lubridate)
library(knitr)
library(DT)

source("helpers.R")

ui <- fluidPage(

    # side bar for inputs
    sidebarPanel(
        fileInput(inputId = "file", label = "", accept = ".fit", buttonLabel = "Select file..."),
        hr(),
        p("Drag markers to set pitch boundary and (1st half) direction of attack."),
        leafletOutput("map"),
        hr(),
        p("Allocate 'laps' to 1st/2nd halves."),
        checkboxGroupInput(inputId = "first_laps", label = "1st half", choices = 1:3, inline = TRUE),
        checkboxGroupInput(inputId = "second_laps", label = "2nd half", choices = 1:3, inline = TRUE),
        hr(),
        p("Input number of goals scored."),
        numericInput(inputId = "goals", label = "Goals", value = 0, min = 0, step = 1),
        hr(),
        p("Write a title for the plot, e.g. the match result."),
        textInput(inputId = "title", label = "", value = "", placeholder = "Plot title..."),
        p("Choose what information to display in the plot subtitle."),
        checkboxGroupInput(inputId = "subtitle", label = "Subtitle", choices = c("Date", "Distance", "Goals"), selected = c("Date", "Distance", "Goals"), inline = TRUE),
        actionButton("goHeatmap", "Generate heatmap"),
        downloadButton('downloadHeatmap', 'Download'),
        width = 6
    ),
    
    # main panel for outputs
    mainPanel(
        plotOutput("heatmap"),
        dataTableOutput("stats"), # TO BE ADDED
        width = 6
    )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
    
    # before inputs are given
    
    map_view <- reactiveValues(
        lng = -1.2163969197125013,
        lat = 54.57826456606962
    )
    
    markers <- reactiveValues(
        id = c("LB", "RB", "RF", "LF"),
        x = rep(0, 4), # x = lng
        y = rep(0, 4) # y = lat
    )
    
    xy_basis <- reactiveValues(
        ex = c(1, 0),
        ey = c(0, 1)
    )
    
    output$map <- renderLeaflet({
        leaflet() %>%
            addProviderTiles("Esri.WorldImagery", group = "Satellite") %>%
            addProviderTiles("OpenStreetMap", group = "Street Map") %>%
            setView(lng = map_view$lng,
                    lat = map_view$lat,
                    zoom = 17) %>%
            addLayersControl(baseGroups = c("Street Map", "Satellite"))
    })
    
    # when file is added
    
    dataInput <- reactive({  
        read_fit(input$file$datapath)
    })
    
    observeEvent(input$file, {
        
        updateCheckboxGroupInput(session, "first_laps", choices = unique(dataInput()$lap), inline = TRUE)
        updateCheckboxGroupInput(session, "second_laps", choices = unique(dataInput()$lap), inline = TRUE)
        
        markers$x <- rep(mean(dataInput()$lng, na.rm = TRUE), times = 4)
        markers$y <- rep(mean(dataInput()$lat, na.rm = TRUE), times = 4)
        
        map_view$lng <- mean(dataInput()$lng, na.rm = TRUE)
        map_view$lat <- mean(dataInput()$lat, na.rm = TRUE)
        
        xy_basis$ex <- ex_basis(markers$x, markers$y, markers$id)
        xy_basis$ey <- ey_basis(markers$x, markers$y, markers$id)
        
        leafletProxy("map") %>%
            setView(lng = map_view$lng, lat = map_view$lat, zoom = 17) %>%
            addMarkers(lng = markers$x,
                       lat = markers$y,
                       label = markers$id,
                       layerId = markers$id,
                       options = markerOptions(draggable = TRUE)) %>%
            addPolylines(lng = dataInput()$lng, lat = dataInput()$lat, col = "red", opacity = 0.5, weight = 0.5) %>%
            addPolygons(lng = c(markers$x, markers$x[1]),
                        lat = c(markers$y, markers$y[1]),
                        layerId = "markerfill",
                        weight = 0,
                        fillColor = "blue", fillOpacity = 0.3)
    })
    
    # when markers are dragged
    
    observeEvent(input$map_marker_dragend, {
        
        markers$x[markers$id == input$map_marker_dragend$id] <- input$map_marker_dragend$lng
        markers$y[markers$id == input$map_marker_dragend$id] <- input$map_marker_dragend$lat
        
        xy_basis$ex <- ex_basis(markers$x, markers$y, markers$id)
        xy_basis$ey <- ey_basis(markers$x, markers$y, markers$id)
        
        leafletProxy("map") %>%
            clearMarkers() %>%
            removeShape(layerId = "markerfill") %>%
            addMarkers(lng = markers$x, 
                       lat = markers$y,
                       label = markers$id,
                       layerId = markers$id,
                       options = markerOptions(draggable = TRUE)) %>%
            addPolygons(lng = c(markers$x, markers$x[1]),
                        lat = c(markers$y, markers$y[1]),
                        layerId = "markerfill",
                        weight = 0,
                        fillColor = "blue", fillOpacity = 0.3)
    })
    
    # when Generate Heatmap is clicked (or inputs are updated thereafter)
    
    soccerData <- reactive({
        req(input$goHeatmap)
        xy_pts <- ll_to_xy(lng = dataInput()$lng, lat = dataInput()$lat, ex = xy_basis$ex, ey = xy_basis$ey)
        marker_pts <- ll_to_xy(lng = markers$x, lat = markers$y, ex = xy_basis$ex, ey = xy_basis$ey)
        df <- dataInput() %>%
            dplyr::mutate(x = xy_pts[1, ], y = xy_pts[2, ]) %>%
            dplyr::mutate(interval_duration = c(NA, diff(timestamp))) %>%
            dplyr::mutate(interval_distance = c(NA, diff(distance))) %>%
            dplyr::filter(lap %in% c(input$first_laps, input$second_laps)) %>%
            dplyr::mutate(period = case_when(lap %in% input$first_laps ~ 1, lap %in% input$second_laps ~ 2)) %>%
            soccermatics::soccerTransform(xMin = min(marker_pts[1, ]), xMax = max(marker_pts[1, ]),
                                          yMin = min(marker_pts[2, ]), yMax = max(marker_pts[2, ]),
                                          method = "manual") %>%
            soccermatics::soccerFlipDirection(periodToFlip = 2)
        return(df)
    })
    
    # create outputs
    
    heatmap <- reactive({
        dist_text <- paste0("Distance: ", round(sum(soccerData()$interval_distance, na.rm = TRUE) / 1000, digits = 2), "km")
        date_text <- paste("Date:", format(lubridate::date(soccerData()$timestamp[1]), "%d %B %Y"))
        goals_text <- paste("Goals:", as.character(input$goals))
        text_vec <- c(
            ifelse("Date" %in% input$subtitle, date_text, NA),
            ifelse("Distance" %in% input$subtitle, dist_text, NA),
            ifelse("Goals" %in% input$subtitle, goals_text, NA))
        subtitle_text <- paste(text_vec[!is.na(text_vec)], collapse = ", ")
        soccerData() %>%
        soccermatics::soccerHeatmap(kde = TRUE, 
                                    title = input$title, 
                                    subtitle = subtitle_text,
                                    arrow = "r")
    })
    
    output$heatmap <- renderPlot({
        heatmap()
    })
    
    output$stats <- renderDataTable({
        soccerData() %>%
            group_by(period) %>%
            summarise(
                duration = sum(interval_duration, na.rm = TRUE),
                distance = sum(interval_distance, na.rm = TRUE))
    })
    
    output$downloadHeatmap <- downloadHandler(
        filename = function() { "heatmap.png" },
        content = function(file) {
            ggsave(file, heatmap())
        })
    
}

shinyApp(ui, server)

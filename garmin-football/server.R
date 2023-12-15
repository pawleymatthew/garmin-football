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

source("helpers.R")

# Define server logic required to draw a histogram
function(input, output, session) {
    
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
        
        markers$x <- rep(mean(dataInput()$lng), times = 4)
        markers$y <- rep(mean(dataInput()$lat), times = 4)
        
        map_view$lng <- mean(dataInput()$lng)
        map_view$lat <- mean(dataInput()$lat)
        
        xy_basis$ex <- ex_basis(markers$x, markers$y, markers$id)
        xy_basis$ey <- ey_basis(markers$x, markers$y, markers$id)
        
        leafletProxy("map") %>%
            setView(lng = map_view$lng, lat = map_view$lat, zoom = 17) %>%
            addMarkers(lng = markers$x,
                       lat = markers$y,
                       label = markers$id,
                       layerId = markers$id,
                       options = markerOptions(draggable = TRUE)) %>%
            addPolylines(lng = dataInput()$lng, lat = dataInput()$lat, col = "red", opacity = 0.5, weight = 0.5)
    })
    
    # when markers are dragged
    
    observeEvent(input$map_marker_dragend, {
        
        markers$x[markers$id == input$map_marker_dragend$id] <- input$map_marker_dragend$lng
        markers$y[markers$id == input$map_marker_dragend$id] <- input$map_marker_dragend$lat
        
        xy_basis$ex <- ex_basis(markers$x, markers$y, markers$id)
        xy_basis$ey <- ey_basis(markers$x, markers$y, markers$id)
        
        leafletProxy("map") %>%
            clearMarkers() %>%
            addMarkers(lng = markers$x, 
                       lat = markers$y,
                       label = markers$id,
                       layerId = markers$id,
                       options = markerOptions(draggable = TRUE))
    })
    
    # when Generate Heatmap is clicked (and inputs are updated thereafter)
    
    soccerData <- reactive({
        req(input$goHeatmap)
        xy_pts <- ll_to_xy(lng = dataInput()$lng, lat = dataInput()$lat, ex = xy_basis$ex, ey = xy_basis$ey)
        marker_pts <- ll_to_xy(lng = markers$x, lat = markers$y, ex = xy_basis$ex, ey = xy_basis$ey)
        df <- dataInput() %>%
            dplyr::mutate(x = xy_pts[1, ], y = xy_pts[2, ]) %>%
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
        soccermatics::soccerHeatmap(df = soccerData(), 
                                    kde = TRUE, 
                                    title = input$title, 
                                    subtitle = input$subtitle,
                                    arrow = "r")
    })
    
    output$heatmap <- renderPlot({
        heatmap()
    })
    
    output$downloadHeatmap <- downloadHandler(
        filename = function() { "heatmap.png" },
        content = function(file) {
            ggsave(file, heatmap())
    })
    
}

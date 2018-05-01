#Goal: To map by Bikeshare Trip Frequency by Day of Week and Hour. 
# template / tutorial: https://rstudio.github.io/leaflet/shiny.html
# This code assumes the following variables are in the environment:
#   - Q3 <- Q3-2016 Bike Share data from City of Toronto Open Data
#   - stations_df <- data frame of all Bike Share stations and their lat/lon.


library(shiny)
library(leaflet)
library(data.table)

ui <- fluidPage(
  titlePanel("Bikeshare Trips - Starting Stations (Q3-2016)"),
  h5("Bikeshares stations that had trips by day of week and hour of day in Q3-2016."),
  leafletOutput("mymap"),
  selectInput(inputId = "day", label = "Day of Week", 
              choices = c("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday")),
  numericInput(inputId = "hour",
               label = "Hour of Day (24-hr)",
               value = "00",
               min="00",
               max="23"))

server <- function(input, output, session){
  stations <- reactive({
    x <- sort(table(Q3[Q3$day == input$day & hour(Q3$trip_start_time)==input$hour,][, "from_station_name"]), decreasing=TRUE)
    x <- merge(x=x, y=stations_df, by.x=1, by.y=c("name"), all.x=TRUE)
    return(x)})
  
  output$mymap <- renderLeaflet({
    leaflet(stations_df) %>%
      addProviderTiles(providers$Stamen.TonerLite,
                       options = providerTileOptions()) %>%
      fitBounds(min(stations_df$lon),min(stations_df$lat),max(stations_df$lon),max(stations_df$lat))
    })
  
  colorpal <- colorBin("YlOrRd", bins=seq(from=1, to=150,length.out=10), na.color="#990000")
  
  observe({
      leafletProxy("mymap") %>% 
      clearMarkers() %>%
      addCircleMarkers(data=stations(), lng=stations()$lon, lat=stations()$lat,
                 weight=2, radius=8, opacity=0.9, color="#000000", fillOpacity=0.9, fillColor=~colorpal(Freq),
                 label=~paste(Var1,Freq,sep=", "))
  })
}


shinyApp(ui = ui, server = server)
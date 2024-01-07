#########################################################################
# Network Analysis Search Trajectory Networks
# Author: Gabriela Ochoa
# Date: January 2024
# STN Visualisation
# Now using the more modern library ggraph
# Plots  Merged STN  models
# Input:  File with STN graph object for a merged model
# Output: Network plots (png) saved in folder
#########################################################################
rm(list = ls(all = TRUE))
library(igraph) # Fundamental graph library
library(ggraph) # Graph visualisation similar to ggplot
library(ggpubr) # For producing grid plots


# Name of instance to process
instance <- "pmed6"    # Indicate name of the instance to process

# It is assumed that the  RData files is in a directory called 'stns'
infolder <- file.path("stns")  # input data
# The output plots will be in a directory called 'plots'
outfolder <- file.path("plots") # output merged plot

size_range <- c(1, 5)  # Size range of nodes

fsize <- 12  # Font size to use by default  
# Manually assign shapes and colors of nodes and edges
# Factor ordering of Node types: Start, Best, End, then alg names alphabetically, shared last
node_shapes <- c(15) # Olny the start shape square
spe_colors <- c("gold") # Special nodes
alg_colors <- c("#fc8d62", "#377eb8", "#4daf4a","#984ea3","#ff7f00")   # Alg1, Alg2, .. up to 5  Algorithms 
shared_col <-  "gray70" #  Shared node: visited by more than one algorithms

# -----------------------------------------------------------------------------
# Plot STN with force-directed (Stress layout)
# Input: STN object
#        bFit: If TRUE, use fitness as the Y coordinate, if FALSE, standard layout
# -----------------------------------------------------------------------------
plot_merged_stn <- function(STN, bFit) {
  mylay <- create_layout(STN, layout = 'kk')
  if (bFit) {
    mylay$y<- V(STN)$Fitness   # Use fitness as the Y coordinate
  }
  p <- ggraph(STN, graph = mylay) + 
    geom_edge_link2(aes(color = Algorithms))+
    geom_node_point(aes(size = Count,
                        color=Type, shape = Type)) +
    scale_size(range = c(1.5, 5), guide = "none") +
    scale_shape_manual(values = node_shapes) +
    scale_color_manual(values = node_colors) +
    scale_edge_colour_manual(values = edge_colors, guide = "none")
  
  if (bFit) { # Fitness layout
    p <- p + theme_bw(base_size = fsize, base_family = "sans") +
      ylab("Fitness") +
      ylim(best, worst) +
      scale_x_continuous(breaks = NULL) +
      guides(size = "none", edge_alpha="none") +
      theme(axis.title.x=element_blank(),
            axis.text.x=element_blank(),
            axis.ticks.x=element_blank()) 
  } else { # Graph layout
    p <- p + theme_graph(base_size = fsize, base_family = "sans", title_face = "plain") +
      ggtitle(instance) 
  }
  return(p)
}
# ---- Process single file for given instance ----------------

fname <- paste0(instance,"_merged_stn.RData")
load(file.path(infolder,fname), verbose = T)

# Set node and edge colors, according to the number of algorithms
# Check if best and end exist before adding them

# Check existence of end and best nodes to add to shapes and colors

if (length(which(V(STNm)$Type == "End")) > 0) {  # Add End color and shape
  spe_colors <- c(spe_colors,  gray(0.3, 0.5))
  node_shapes <- c(node_shapes,17)  # Triangle
}


if (length(which(V(STNm)$Type == "Best")) > 0) {  # Add End color and shape
  spe_colors <- c(spe_colors,  "red")
  node_shapes <- c(node_shapes,19)  # Triangle
}

node_shapes <- c(node_shapes,rep(20,5))  # Small circles for the rest 


node_colors <- c(spe_colors, alg_colors[1:num_alg], shared_col)
edge_colors <- c(alg_colors[1:num_alg], shared_col)

p <- plot_merged_stn(STNm, F)
pf <- plot_merged_stn(STNm, T)  

foname <- paste0(instance,"_merged_stn.png")

arr <- ggarrange(p, pf, common.legend = T, legend="right", nrow=1, ncol=2)

ggsave(arr, filename = file.path(outfolder,foname),  device = "png", width = 12, height =6)


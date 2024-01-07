#########################################################################
# Network Analysis Search Trajectory Networks
# Author: Gabriela Ochoa
# Date: September 2022
# STN Visualisation
# Now using the more modern library ggraph
# Plots for single algorithm, as opposed to merging several algorithms
# Input:  Folder with STN graph objects for a single algorithm
# Output: Network plots (png) saved in folder
#########################################################################
rm(list = ls(all = TRUE))
library(igraph) # Fundamental graph library
library(ggraph) # Graph visualisation similar to ggplot
library(ggpubr) # For producing grid plots


# Location of data files. Add here the folder containing  your data files
instance <- "pmed7"    # Indicate name of the instance to process

size_range <- c(1, 5)  # Size range of nodes


# It is assumed that the instance RData files with STN models are in a folder called 'stns' in a subfolder with the instance name
infolder <- file.path("stns", instance)  # input data
# The output plots will be in a directory called 'plots'
outfolder <- file.path("plots", instance) # output plots
dir.create(outfolder, recursive = TRUE, showWarnings = FALSE)



fsize <- 12  # Font size to use by default  
# Manually assign colors and shapes of nodes
# Factor for node types: 'Start', 'Medium', 'End', Best'
nshapes <- c(22, 21, 24,23) 
nfills<- c("gold","cadetblue2", gray(0.3, 0.5), "red") 


# Edge Colors
# STN models have 3 types of edges:  Improvement, Neutral, Worsening
# alpha is for transparency: (as an opacity, 0 means fully transparent,  max (255) opaque)
edge_colors <- c("gray50", rgb(0,0,250, max = 255, alpha = 180), rgb(0,250,0, max = 255, alpha = 180) )

# -----------------------------------------------------------------------------
# Plot STN with Fitness as the Y coordinate
# Input: dfile: Data file with STN object, 
#        bfit: TUE for fitness layout, FALSE for force-directed layout
# -----------------------------------------------------------------------------

plot_stn_fit <- function(dfile, bfit) {
  aux <- strsplit(dfile,"_")[[1]]
  tit <- paste(aux[1], aux[2])
  print(tit)
  load( file.path(infolder,dfile), verbose = F)
  mylay <- create_layout(STN, layout = 'kk')
  if (bfit) {
    mylay$y<- V(STN)$Fitness 
  }    
  p <- ggraph(STN, graph = mylay) + 
    geom_edge_link(aes(color = Type)) +
    geom_node_point(aes(size = Count, fill=Type, shape=Type)) +
    scale_size(range = size_range, guide = 'none') +
    scale_shape_manual(values = nshapes, 
                       labels = c('Start', 'Medium', 'End', 'Best'), drop = F) +
    scale_fill_manual(values = nfills, 
                      labels = c('Start', 'Medium', 'End', 'Best'), drop = F) +
    scale_edge_color_manual(values = edge_colors, guide = "none") 
  if (bfit) { # Fitness layout
    p <- p + theme_bw(base_size = fsize, base_family = "sans") +
      ylab("Fitness") +
     # ylim(best, worst) +  # In case algorithms want to be contrasted
      scale_x_continuous(breaks = NULL) +
      guides(size = "none", edge_alpha="none") +
      theme(axis.title.x=element_blank(),
            axis.text.x=element_blank(),
            axis.ticks.x=element_blank()) 
  } else { # Graph layout
    p <- p + theme_graph(base_size = fsize, base_family = "sans", title_face = "plain") +
      ggtitle(tit) 
  }
  return(p)
}

# ---- Process all files in the given input folder ----------------

dataf <- list.files(infolder)

p <-  lapply(dataf, plot_stn_fit, F)    # Standard force-directed layout
pf <- lapply(dataf, plot_stn_fit, T)    # Layout where the Y coordinate is fitness

foname <- paste0(instance,"_stn.png")

# Creates one plot for each algorithm using the two layouts

for (i in 1:length(dataf)) {
  arr <- ggarrange(p[[i]], pf[[i]],
                   common.legend = T, legend="right",
                   nrow=1, ncol=2)
  foname <- paste0(substr(dataf[i], 1, nchar(dataf[i]) - 5), "png") 
  print(foname)
  ggsave(arr, filename = file.path(outfolder,foname),  device = "png", width = 12, height =6)
  
}
  



